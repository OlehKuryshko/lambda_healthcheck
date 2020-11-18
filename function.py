import json
import boto3
import decimal
from botocore.vendored import requests
from boto3.dynamodb.conditions import Key, Attr
from datetime import datetime 

_return = []
    
def send_email(url, log):
    name = 'Mike Jordan'
    source = 'sourse_email'
    subject = "Lambda Healthcheck Notification"
    message = "Server with following url is down: " + url + '\n'
    destination = "destination_email"
    _message = "Message from: " + name + "\nEmail: " + source + "\nReason: " + message + "\nLogs:\n" + str(log).replace('\\n', '\n')

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
                print(url + ' is ok (healthy), setting FailedChecks to 0')
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
                    'datetime': str(datetime.now()),
                    'url' : url,
                    'statusCode': r.status_code,
                    'body': json.dumps(r.text)
                })
            else:
                raise requests.exceptions.ConnectionError
        except (requests.exceptions.ConnectionError, requests.exceptions.Timeout):
            log = []
            print(url + ' is not ok (unhealthy), incremetning FailedChecks')
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
            if(r.status_code == 0):
                log = {
                    'datetime': str(datetime.now()),
                    'url' : url,
                    'body': json.dumps("Failed connect to " + url + "; Connection refused") 
                }
                _return.append(log)
            else:
                log = {
                    'datetime': str(datetime.now()),
                    'url' : url,
                    'statusCode': r.status_code,
                    'body': r.text
                }
                _return.append(log)
                r.status_code == 0
            if failedHealthChecks['Attributes']['FailedChecks'] >= 3:
                print("####################################################")
                print("server " + url  + " is down, sending email ...")
                print(r.status_code)
                print("####################################################")
                send_email(url, log)
                
def lambda_handler(event, context):

   
    table = boto3.resource('dynamodb', region_name='us-west-2').Table('oleh-lambda-table')
    
    checklist = fake_checklist()
    update_table(checklist, table)
    
    healthcheck(checklist, table)      
    
    return json.dumps(_return)