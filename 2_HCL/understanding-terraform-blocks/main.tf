# 파일을 로컬에 생성하는 예제

# Provider 없이 로컬 파일 리소스 사용
resource "local_file" "example" {
  filename = "${path.module}/example.txt"
  content  = "Hello, Terraform!"
}

# 출력 블록: 생성된 파일의 경로를 출력
output "file_path" {
  value = local_file.example.filename
}
