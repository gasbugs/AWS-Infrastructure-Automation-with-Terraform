# AWS Provider
aws_region        = "us-east-1"
aws_profile       = "my-sso"
pub_key_file_path = "C:\\users\\isc03\\.ssh\\my-key.pub"

# 사용할 AMI ID
ami_id = "ami-09fc4e913b9959f26" # packer를 통해 생성된 ami를 지정 

# 오토 스케일링 그룹의 원하는 설정
instance_type    = "t2.micro"
desired_capacity = 2
max_size         = 4
min_size         = 2
