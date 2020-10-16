import json
import boto3
import decimal
from botocore.vendored import requests
from boto3.dynamodb.conditions import Key, Attr

_return = []
    
def send_email(url):
    name = 'Milan'
    source = 'mmel2@softserveinc.com'
    subject = "Lambda Healthcheck Notification"
    message = "Server with following url is down: " + url
    destination = "milanmelnykov@gmail.com"
    _message = "Message from: " + name + "\nEmail: " + source + "\nMessage content: " + message

    client = boto3.client('ses')

    client.send_email(
        Destination={
            'ToAddresses': [destination]
            },
        Message={
            'Body': {
                'Text': {
                    'Charset': 'UTF-8',
                    'Data': _message,
                },
            },
            'Subject': {
                'Charset': 'UTF-8',
                'Data': subject,
            },
        },
        Source = source,
    )

def fake_checklist():
    checklist = []
    checklist.append('https://www.google.com/')
    checklist.append('http://greencity.azurewebsites.net/')
    checklist.append('http://fakeone')
    return checklist

def get_table_urls(table):
    table_urls = []
    response = table.scan()
    items = response['Items']
    if items:
        for x in items:
            table_urls.append(x.get('Address'))
        return table_urls
    else:
        return []
    
def put_new_urls(new_urls, table):
    for url in new_urls:
        table.put_item(
            Item={
                'Address': url,
                'FailedChecks': 0
            }
        )
        
def delete_old_urls(old_urls,table):
    for url in old_urls:
        table.delete_item(
            Key={
                'Address': url
            }    
        )

def update_table(checklist, table):
    table_urls = get_table_urls(table)
    
    new_urls = list(set(checklist) - set(table_urls))
    old_urls = list(set(table_urls) - set(checklist))

    for url in new_urls:
        put_new_urls(new_urls,table)
    for url in old_urls:
        delete_old_urls(old_urls,table)


def healthcheck(checklist, table):
    for url in checklist:
        try:
            r = requests.get(url, timeout=5)
            if r.status_code < 400:
                print(url + ' is ok, setting FailedChecks to 0')
                table.update_item(
                    Key={
                        'Address': url
                    },
                    UpdateExpression="set FailedChecks = :val",
                    ExpressionAttributeValues={
                        ':val': decimal.Decimal(0)
                    },
                    ReturnValues="UPDATED_NEW"
                )
                _return.append({
                    'url' : url,
                    'statusCode': r.status_code,
                    'body': json.dumps(r.text)
                })
            else:
                raise requests.exceptions.ConnectionError
        except (requests.exceptions.ConnectionError, requests.exceptions.Timeout):
            print(url + ' is not ok, incremetning FailedChecks')
            failedHealthChecks = table.update_item(
                Key={
                    'Address': url
                },
                UpdateExpression="set FailedChecks = FailedChecks + :val",
                ExpressionAttributeValues={
                    ':val': decimal.Decimal(1)
                },
                ReturnValues="UPDATED_NEW"
            )
            if failedHealthChecks['Attributes']['FailedChecks'] >= 3:
                print("server " + url  + " is down, sending email ...")
                send_email(url)
                # not sure
                # table.update_item(
                #     Key={
                #         'Address': url
                #     },
                #     UpdateExpression="set FailedChecks = :val",
                #     ExpressionAttributeValues={
                #         ':val': decimal.Decimal(0)
                #     },
                #     ReturnValues="UPDATED_NEW"
                # )
            if(r.status_code == None):
                _return.append({
                    'url' : url,
                    'statusCode': r.status_code,
                    'body': json.dumps("There is an error")
                })
            else:
                _return.append({
                    'url' : url,
                    'statusCode': r.status_code,
                    'body': json.dumps(r.text)
                })

def lambda_handler(event, context):

    # dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
    # table = dynamodb.Table('milan-lambda-table')
   
    table = boto3.resource('dynamodb', region_name='us-east-1').Table('milan-lambda-table')
    
    checklist = fake_checklist()
    update_table(checklist, table)
    
    healthcheck(checklist, table)      
    
    # return _return
    return json.dumps(_return)
