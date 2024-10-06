import boto3

# AWS DynamoDB 리소스 생성
dynamodb = boto3.resource('dynamodb')

# DynamoDB 테이블 이름 (main.tf에서 설정한 이름과 동일해야 함)
table_name = 'Users'

# 테이블 객체 생성
table = dynamodb.Table(table_name)

def put_item(user_id, name, email):
    """
    DynamoDB 테이블에 사용자 정보를 추가하는 함수
    """
    try:
        response = table.put_item(
            Item={
                'UserId': user_id,
                'Name': name,
                'Email': email
            }
        )
        print(f"PutItem succeeded: {response}")
    except Exception as e:
        print(f"Error adding item to table: {e}")

def get_item(user_id):
    """
    DynamoDB 테이블에서 UserId로 사용자 정보를 가져오는 함수
    """
    try:
        response = table.get_item(
            Key={
                'UserId': user_id
            }
        )
        if 'Item' in response:
            return response['Item']
        else:
            print(f"No item found with UserId: {user_id}")
    except Exception as e:
        print(f"Error retrieving item from table: {e}")

def main():
    # 데이터 쓰기 예제
    put_item('user1', 'John Doe', 'john.doe@example.com')
    put_item('user2', 'Jane Doe', 'jane.doe@example.com')

    # 데이터 읽기 예제
    user = get_item('user1')
    if user:
        print(f"Retrieved user: {user}")

if __name__ == "__main__":
    main()
