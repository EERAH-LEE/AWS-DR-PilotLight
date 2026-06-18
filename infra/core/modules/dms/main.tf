#DMS 서브넷 그룹 - DMS 복제 인스턴스가 위치할 서브넷
resource "aws_dms_replication_subnet_group" "name" {
  replication_subnet_group_id          = "dms-subnetgroup-${var.namespace}"
  replication_subnet_group_description = "DMS subnet group for DR"
  subnet_ids                           = var.subnet_ids

  tags = {
    Name = "dms-subnetgroup-${var.namespace}"
  }
}

#DMS 복제 인스턴스 - Azure MySQL -> AWS RDS 복제 엔진
resource "aws_dms_replication_instance" "main" {
  replication_instance_id    = "dms-${var.namespace}"
  replication_instance_class = "dms.t3.medium"
  allocated_storage          = 20

  replication_subnet_group_id = aws_dms_replication_subnet_group.name.id
  vpc_security_group_ids      = [var.dms_sg_id]

  publicly_accessible = false #프라이빗 서브넷 사용

  tags = {
    Name = "dms-${var.namespace}"
  }
}

#소스 엔드포인트 - Azure MySQL
resource "aws_dms_endpoint" "source" {
  endpoint_id   = "source-mysql-${var.namespace}"
  endpoint_type = "source"
  engine_name   = "mysql"

  server_name   = var.source_host
  port          = 3306
  username      = var.source_username
  password      = var.source_password
  database_name = "kbeauty"

  ssl_mode = "none" #require_secure_transport OFF 설정했으므로

  tags = {
    Name = "source-mysql-${var.namespace}"
  }
}

#대상 엔드포인트 - AWS RDS MySQL
resource "aws_dms_endpoint" "target" {
  endpoint_id   = "target-mysql-${var.namespace}"
  endpoint_type = "target"
  engine_name   = "mysql"

  server_name   = var.target_endpoint
  port          = 3306
  username      = var.target_username
  password      = var.target_password
  database_name = "kbeauty"

  tags = {
    Name = "target-mysql-${var.namespace}"
  }
}


#DMS 복제 태스크 - 실제 데이터 이동 작업 정의
# 복제 인스턴스와 소스/대상 엔드포인트를 연결해서 실제 복제를 수행하는 태스크
resource "aws_dms_replication_task" "main" {
  replication_task_id      = "task-${var.namespace}"
  migration_type           = "full-load-and-cdc"                                          #초기 전체복사 후 변경분 지속 복제 (change data capture)
  replication_instance_arn = aws_dms_replication_instance.main.replication_instance_arn #위에서 만드 복제 인스턴스 연결
  source_endpoint_arn      = aws_dms_endpoint.source.endpoint_arn                         #Azure MySQL 엔드포인트 연결   
  target_endpoint_arn      = aws_dms_endpoint.target.endpoint_arn                         #AWS RDS 엔드포인트 연결

  #어떤 테이블을 복제할지 JSON으로 정의 (테이블 매핑 규칙)
  table_mappings = jsonencode({
    rules = [{                    #json 구조라서 필드명에 - 들어감
      rule-type   = "selection"   # 테이블 선택(단순복제라 셀렉션써야함)
      rule-id     = "1"           #이 규칙의 번호 (여러 개면 1,2,3 ...)
      rule-name   = "include-all" #그냥 식별용 이름, 마음대로 지으면됌.
      rule-action = "include"     #선택된 테이블을 포함 (exclude로 하면 '제외')
      object-locator = {          # 어떤 테이블을 선택할지 위치 지정
        schema-name = "kbeauty"   #kbeauty 테이터베이스에서
        table-name  = "%"         #모든 테이블 
      }
    }]
  })

  #복제 태스크 세부 동작 설정
  replication_task_settings = jsonencode({
    TargetMetadata = {
      SupportLobs        = true  #LOB(이미지 등 대용량 데이터)지원
      FullLobMode        = false #LOB 전체 모드 off (크기 제한 모드 사용)
      LimitedSizeLobMode = true  #LOB 크기제한 모드 on
      LobMaxSize         = 32    # LOB 최대 32KB
    }
    FullLoadSettings = {
      TargetTablePrepMode = "DO_NOTHING" #초기 전체복사 시 대상 테이블 건드리지 않음 (이미 스키마 있을 경우)
    }
    Logging = {
      EnableLogging = true #CloudWatch에 복제 로그 남기 (오류 추적용)
    }
  })

  tags = {
    Name = "task-${var.namespace}"
  }
}




##############################################################
###########################역뱡향##############################
##############################################################


# ── 역방향 소스 엔드포인트: AWS RDS ──────────────────────────────
# 정방향에서는 RDS가 대상이었지만, 역방향에서는 소스가 됨
# failback 시 RDS에 쌓인 데이터를 Azure MySQL로 보내는 출발점
resource "aws_dms_endpoint" "source_rds" {
  endpoint_id   = "source-rds-${var.namespace}"
  endpoint_type = "source"
  engine_name   = "mysql"

  server_name   = var.target_endpoint  # 기존 RDS 엔드포인트 변수 재사용
  port          = 3306
  username      = var.target_username
  password      = var.target_password
  database_name = "kbeauty"

  tags = { Name = "source-rds-${var.namespace}" }
}


# ── 역방향 대상 엔드포인트: Azure MySQL ──────────────────────────
# 정방향에서는 Azure MySQL이 소스였지만, 역방향에서는 대상이 됨
# VPN 터널을 통해 Azure private IP(10.0.4.x)로 접근
resource "aws_dms_endpoint" "target_azure_mysql" {
  endpoint_id   = "target-azure-mysql-${var.namespace}"
  endpoint_type = "target"
  engine_name   = "mysql"

  server_name   = var.source_host      # 기존 Azure MySQL host 변수 재사용
  port          = 3306
  username      = var.source_username
  password      = var.source_password
  database_name = "kbeauty"

  ssl_mode = "none"  # Azure MySQL require_secure_transport = OFF 상태

  tags = { Name = "target-azure-mysql-${var.namespace}" }
}


# ── 역방향 복제 태스크 ────────────────────────────────────────────
# DR 시 RDS → Azure MySQL 동기화용
# 평상시에는 중지 상태로 두고, failback 시에만 시작
# full-load-and-cdc: 시작 시 RDS 전체 복사 후 변경분 실시간 동기화
# → binlog 위치 계산 불필요, 언제 시작해도 최신 상태로 맞춰짐
resource "aws_dms_replication_task" "failback" {
  replication_task_id      = "task-failback-${var.namespace}"
  migration_type           = "full-load-and-cdc"
  replication_instance_arn = aws_dms_replication_instance.main.replication_instance_arn
  source_endpoint_arn      = aws_dms_endpoint.source_rds.endpoint_arn
  target_endpoint_arn      = aws_dms_endpoint.target_azure_mysql.endpoint_arn

  table_mappings = jsonencode({
    rules = [{
      rule-type   = "selection"
      rule-id     = "1"
      rule-name   = "include-all"
      rule-action = "include"
      object-locator = {
        schema-name = "kbeauty"
        table-name  = "%"
      }
    }]
  })

  replication_task_settings = jsonencode({
    TargetMetadata = {
      SupportLobs        = true
      FullLobMode        = false
      LimitedSizeLobMode = true
      LobMaxSize         = 32
    }
    FullLoadSettings = {
      # Azure MySQL에 기존 데이터 있을 수 있으므로 TRUNCATE 후 로드
      TargetTablePrepMode = "TRUNCATE_BEFORE_LOAD"
    }
    Logging = {
      EnableLogging = true
    }
  })

  tags = { Name = "task-failback-${var.namespace}" }
}
