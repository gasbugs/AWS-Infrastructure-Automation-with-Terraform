# AWS Provider
aws_region        = "us-east-1"
aws_profile       = "my-sso"
pub_key_file_path = "C:\\users\\isc03\\.ssh\\my-key.pub"

# 사용할 AMI ID
# ami_id  = "ami-062cc7df84fdca122" # packer를 통해 생성된 nginx_old 이미지 지정
# asg_tag = "old-nginx-asg"

ami_id  = "ami-0b88b06de5e775c5f" # packer를 통해 생성된 nginx_new 이미지 지정
asg_tag = "new-nginx-asg"

# 오토 스케일링 그룹의 원하는 설정
instance_type    = "t2.micro"
desired_capacity = 2
max_size         = 4
min_size         = 1

# certs
private_key_file_path      = "./certs/private-key.pem"
certificate_body_file_path = "./certs/certificate.pem"
# certificate_chain_file_path= ""
