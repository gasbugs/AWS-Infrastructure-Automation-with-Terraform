# AWS Provider
aws_region        = "us-east-1"
aws_profile       = "my-sso"
pub_key_file_path = "C:\\users\\isc03\\.ssh\\my-key.pub"

# 사용할 AMI ID
ami_id = "ami-07c7a0470169bb4a0" # packer를 통해 생성된 httpd 이미지 지정
# ami_id = "ami-0ffe031cd9187c815" # packer를 통해 생성된 nginx 이미지 지정

# 오토 스케일링 그룹의 원하는 설정
instance_type    = "t2.micro"
desired_capacity = 2
max_size         = 4
min_size         = 2

# certs
private_key_file_path      = "./certs/private-key.pem"
certificate_body_file_path = "./certs/certificate.pem"
# certificate_chain_file_path= ""
