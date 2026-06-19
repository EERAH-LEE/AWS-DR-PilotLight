#------------------------------------------------------
# SNS Topic
# CloudWatch Alarm 발동 시 여기로 알림이 옴
#------------------------------------------------------
resource "aws_sns_topic" "dr_alert" {
  name = "sns-${var.namespace}-dr-alert"
}




#------------------------------------------------------
# CloudWatch Alarm
# Lambda가 기록한 커스텀 메트릭 감시
# check_interval_minutes 주기로 체크하다가
# alarm_minutes 동안 연속 실패 시 SNS로 알림
#------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "azure_health" {
  alarm_name        = "alarm-${var.namespace}-azure-down"
  alarm_description = "Azure AGW ${local.alarm_minutes}분 이상 비정상 - DR 검토 필요"

  # Lambda가 Custom/AzureHealth 네임스페이스에 기록한 메트릭 감시
  namespace   = "Custom/AzureHealth"
  metric_name = "AGWHealthStatus"

  # Lambda 실행 주기와 맞춰야 함
  period = local.period

  # 몇 번 연속 실패 시 알람 발동
  # ex) 5분 주기 * 3번 = 15분
  evaluation_periods  = local.evaluation_periods
  statistic           = "Minimum"                 # 기간 내 최솟값 기준(하나라도 0이면 비정상)
  threshold           = 1                         # 1 미만이면 알람 (0=비정상)
  comparison_operator = "LessThanThreshold"       #메트릭 < 1 이면 알람 발동

  # 데이터 없을 때도 비정상으로 처리
  treat_missing_data = local.treat_missing_data

  alarm_actions = [aws_sns_topic.dr_alert.arn]    # 비정상 시 SNS 발송
  ok_actions    = [aws_sns_topic.dr_alert.arn]    # 정상 복구 시에도 SNS 발송 (복구 알람)
}





#------------------------------------------------------
# IAM Role - Lambda용
# CloudWatch 메트릭 기록 + 기본 실행 권한
#------------------------------------------------------
resource "aws_iam_role" "lambda" {
  name = "role-${var.namespace}-health-checker"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# Lambda 기본 실행 권한 (CloudWatch Logs 쓰기)
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# CloudWatch 커스텀 메트릭 기록 권한
resource "aws_iam_role_policy" "cloudwatch_put" {
  role = aws_iam_role.lambda.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["cloudwatch:PutMetricData"]
      Resource = "*"
    }]
  })
}





#------------------------------------------------------
# Lambda 함수
# Azure AGW를 주기적으로 호출해서 응답 검증
# 결과를 CloudWatch 커스텀 메트릭으로 기록
#------------------------------------------------------
data "archive_file" "lambda" {
  type        = "zip"
  output_path = "/tmp/health_checker.zip"

  source {
    filename = "index.py"
    content  = <<-PYTHON
import json
import urllib.request
import urllib.error
import boto3
import os

# Slack Incoming Webhook으로 메시지 전송
def send_slack(message):
    webhook_url = os.environ["SLACK_WEBHOOK_URL"]
    data = json.dumps({"text": message}).encode()
    req = urllib.request.Request(webhook_url, data=data, method="POST")
    req.add_header("Content-Type", "application/json")
    urllib.request.urlopen(req)

def handler(event, context):
    # SNS에서 온 이벤트 = CloudWatch Alarm 15분 알람
    if "Records" in event and event["Records"][0]["EventSource"] == "aws:sns":
        send_slack("[DR 경보] Azure 15분 이상 비정상! DR 전환 검토 필요")
        return


    agw_fqdn = os.environ["AZURE_AGW_FQDN"]
    cw = boto3.client("cloudwatch", region_name="ap-northeast-2")

    if os.environ.get("SUPPRESS_ALERTS") == "true":
        print("Alert suppression enabled. Skipping health check.")
        return {"status": "suppressed"}

    status = 0  # 기본값: 비정상

    try:
        url = f"http://{agw_fqdn}/health"  #https:http
        req = urllib.request.Request(url)
        req.add_header("Host", "www.sue019522.shop")
        res = urllib.request.urlopen(req, timeout=10)

        # 응답코드 확인
        if res.status == 200:
            #body = json.loads(res.read().decode())
            status = 1 #200이면 정상

            # /health 엔드포인트가 {"status": "ok"} 반환하는지 확인
            # 앱에서 DB, Redis 등 내부 상태까지 검증한 결과
            #if body.get("status") == "ok":
                #status = 1  # 진짜 정상

    except urllib.error.HTTPError as e:
        # 4xx, 5xx 에러
        print(f"HTTP Error: {e.code}")
    except Exception as e:
        # 타임아웃, 연결 불가 등
        print(f"Error: {str(e)}")

    # 비정상일 때 Slack 알림 전송
    if status == 0:
        send_slack(
            ":rotating_light: *Azure 서비스 경보*\n"
            f"Azure AGW({agw_fqdn}) 비정상 감지\n"
            "담당자 Azure 인프라를 확인해 주세요."
        )

    # CloudWatch에 결과 기록
    # 1 = 정상, 0 = 비정상
    cw.put_metric_data(
        Namespace="Custom/AzureHealth",
        MetricData=[{
            "MetricName": "AGWHealthStatus",
            "Value": status,
            "Unit": "None",
            "Dimensions": [{
                "Name": "Target",
                "Value": agw_fqdn
            }]
        }]
    )

    print(f"Health check result: {status} for {agw_fqdn}")
    return {"status": status}
PYTHON
  }
}




resource "aws_lambda_function" "health_checker" {
  function_name = "fn-${var.namespace}-health-checker"
  role          = aws_iam_role.lambda.arn
  runtime       = "python3.12"
  handler       = "index.handler"
  filename      = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  timeout       = 30  # AGW 응답 대기 최대 30초

  environment {
    variables = {
      AZURE_AGW_FQDN    = var.azure_agw_fqdn
      SLACK_WEBHOOK_URL = var.slack_webhook_url
      SUPPRESS_ALERTS   = tostring(local.SUPPRESS_ALERTS)
    }
  }
}




#------------------------------------------------------
# IAM Role - EventBridge Scheduler용
# Lambda 호출 권한
#------------------------------------------------------
resource "aws_iam_role" "scheduler" {
  name = "role-${var.namespace}-scheduler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "scheduler.amazonaws.com" }
    }]
  })
}



resource "aws_iam_role_policy" "scheduler_invoke" {
  role = aws_iam_role.scheduler.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["lambda:InvokeFunction"]
      Resource = aws_lambda_function.health_checker.arn
    }]
  })
}




#------------------------------------------------------
# EventBridge Scheduler
# check_interval_minutes 마다 Lambda 실행
#------------------------------------------------------
resource "aws_scheduler_schedule" "health_check" {
  name = "schedule-${var.namespace}-health-check"

  # rate 표현식으로 주기 설정
  flexible_time_window { mode = "OFF" }
  schedule_expression = "rate(${local.check_interval_minutes} minutes)"

  target {
    arn      = aws_lambda_function.health_checker.arn
    role_arn = aws_iam_role.scheduler.arn
  }
}



# SNS가 기존 Lambda를 직접 호출하도록 구독
# CloudWatch Alarm 발동 → SNS → 이 Lambda 호출
resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = aws_sns_topic.dr_alert.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.health_checker.arn
}

# SNS가 Lambda 호출할 수 있도록 권한 부여
resource "aws_lambda_permission" "sns" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.health_checker.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.dr_alert.arn
}
