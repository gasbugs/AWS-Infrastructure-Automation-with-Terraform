# AWS Provider
aws_region        = "us-east-1"
aws_profile       = "my-sso"
pub_key_file_path = "C:\\users\\isc03\\.ssh\\my-key.pub"

# 사용할 AMI ID
ami_id = "ami-0601dda195a5d5fcc" # packer를 통해 생성된 ami를 지정 

# 오토 스케일링 그룹의 원하는 설정
instance_type    = "t2.micro"
desired_capacity = 2
max_size         = 4
min_size         = 2

# certs
private_key_file_path      = "./certs/private-key.pem"
certificate_body_file_path = "./certs/certificate.pem"
# certificate_chain_file_path= ""
