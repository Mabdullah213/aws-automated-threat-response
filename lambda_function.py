import json
import boto3

# Initialize the WAF client
waf_client = boto3.client('wafv2')

def lambda_handler(event, context):
    print("Received event: ", json.dumps(event))

    # --- 1. Extract Attacker IP ---
    # GuardDuty findings have a specific structure we need to parse
    try:
        finding_details = event.get('detail', {})
        service_details = finding_details.get('service', {})
        action_details = service_details.get('action', {})
        network_connection_details = action_details.get('networkConnectionAction', {})
        remote_ip_details = network_connection_details.get('remoteIpDetails', {})
        attacker_ip = remote_ip_details.get('ipAddressV4')

        if not attacker_ip:
            print("Could not extract attacker IP from the event.")
            return
            
        print(f"Extracted attacker IP: {attacker_ip}")

    except Exception as e:
        print(f"Error parsing event: {e}")
        return

    # --- 2. Get WAF IP Set Details ---
    # We need the current LockToken to update the IP Set
    try:
        ip_set_name = 'malicious-ips' # The name of the IP Set you created
        scope = 'CLOUDFRONT' # Use 'REGIONAL' if your WAF is not for CloudFront
        
        # Get the IP set ID
        response_list = waf_client.list_ip_sets(Scope=scope)
        ip_set = next((s for s in response_list['IPSets'] if s['Name'] == ip_set_name), None)
        
        if not ip_set:
            print(f"IP Set '{ip_set_name}' not found.")
            return
            
        ip_set_id = ip_set['Id']
        
        # Get the Lock Token
        response_get = waf_client.get_ip_set(Name=ip_set_name, Scope=scope, Id=ip_set_id)
        lock_token = response_get['LockToken']
        current_ips = [cidr.split('/')[0] for cidr in response_get['IPSet']['Addresses']]

    except Exception as e:
        print(f"Error getting WAF IP Set: {e}")
        return

    # --- 3. Update WAF IP Set ---
    # Add the attacker's IP if it's not already in the list
    if attacker_ip in current_ips:
        print(f"IP {attacker_ip} is already in the IP Set. No update needed.")
        return

    try:
        new_addresses = response_get['IPSet']['Addresses']
        new_addresses.append(f"{attacker_ip}/32") # Add the new IP in CIDR format
        
        waf_client.update_ip_set(
            Name=ip_set_name,
            Scope=scope,
            Id=ip_set_id,
            Addresses=new_addresses,
            LockToken=lock_token
        )
        print(f"Successfully blocked IP: {attacker_ip}")
        
    except Exception as e:
        print(f"Error updating WAF IP Set: {e}")
        return
        
    return {
        'statusCode': 200,
        'body': json.dumps(f'Successfully blocked IP: {attacker_ip}')
    }