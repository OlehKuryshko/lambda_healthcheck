import json
import boto3
import decimal
from botocore.vendored import requests
from boto3.dynamodb.conditions import Key, Attr
from datetime import datetime 

_return = []
    
def send_email(url, log):
    name = 'Milan'
    source = 'mmel2@softserveinc.com'
    subject = "Lambda Healthcheck Notification"
    message = "Server with following url is down: " + url + '\n'
    destination = "milanmelnykov@gmail.com"
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

def get_elastic_urls(ec2_ob,fv):
    f={"Name":"tag:Env" , "Values": [fv]}
    hosts=[]
    for each_in in ec2_ob.instances.filter(Filters=[f]):
        hosts.append(each_in.private_ip_address)
    return hosts
    
def elastic_healthcheck(checklist, table):
    _status_code = 0
    for url in checklist:
        try:
            r = requests.get('http://' + url + ':9200/_cluster/health?pretty=true', timeout=5)
            _status_code = r.status_code
            if _status_code < 400:
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
                    'datetime': str(datetime.now()),
                    'url' : url,
                    'statusCode': _status_code,
                    # 'body': json.dumps(r.text)
                    'body': r.text
                })
                _status_code = 0
            else:
                raise requests.exceptions.ConnectionError
        except (requests.exceptions.ConnectionError, requests.exceptions.Timeout):
            # global _status_code
            log = []
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
            if(_status_code == 0):
                log = {
                    'datetime': str(datetime.now()),
                    'url' : url,
                    'body': json.dumps("Failed connect to " + url + ":9200; Connection refused") 
                }
                _return.append(log)
            else:
                log = {
                    'datetime': str(datetime.now()),
                    'url' : url,
                    'statusCode': _status_code,
                    # 'body': json.dumps(r.text)
                    'body': r.text
                }
                _return.append(log)
                _status_code == 0
            if failedHealthChecks['Attributes']['FailedChecks'] >= 3:
                print("####################################################")
                print("server " + url  + " is down, sending email ...")
                print(_status_code)
                print("####################################################")
                send_email(url, log)

def lambda_handler(event, context):

    table = boto3.resource('dynamodb', region_name='us-east-1').Table('milan-lambda-table')
    
    elasticsearch_url_list=get_elastic_urls(boto3.resource("ec2","us-east-1"),'mielasticsearch')
    
    update_table(elasticsearch_url_list, table)

    elastic_healthcheck(elasticsearch_url_list, table) 

    return _return