#s3 버킷 - DR 발동 시 ESK 올라오는 동안 보여줄 정적 점검 페이지 호스팅
resource "aws_s3_bucket" "dr-webpage" {
  bucket = local.bucket_name

  tags = {
    Name = local.bucket_name
  }
}

#s3 퍼블릭 액세스 차단 설정 - CloudFront만 접근, 퍼블릭 접근 막음
resource "aws_s3_bucket_public_access_block" "dr-webpage" {
  bucket = aws_s3_bucket.dr-webpage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#s3 정적 웹사이트 설정
resource "aws_s3_bucket_website_configuration" "dr-webpage" {
  bucket = aws_s3_bucket.dr-webpage.id

  index_document {
    suffix = "index.html"  #기본 진입 페이지
  }
}

#점검 페이지 HTML 파일 업로드
resource "aws_s3_object" "index" {
  bucket = aws_s3_bucket.dr-webpage.id
  key = "index.html"
  content_type = "text/html"

  source = "${path.module}/static/index.html"  #모듈 폴더 기준 상대경로
  etag = filemd5("${path.module}/static/index.html") #파일 변경 감지용
}
# source = ... 에서 path.module은 현재 모듈 폴더의 절대경로 (테라폼 내장 변수)
# etag = s3 오브젝트의 체크섬(파일 내용 감지용 태그), 없으면 파일 내용 수정해도 테라폼이 변경을 못 잡음
# filemd5() 는 파일 내용을 MD5 해시로 변환하는 테라폼 함수
# etag는 파일 내용이 바뀌면 terraform이 자동으로 감지해서 s3에 재업로드
# 따로 넣을 html 파일이 없다면 content = <<-EOF 로 시작하는 HTML 작성
