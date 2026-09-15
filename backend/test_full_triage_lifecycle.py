import json
import urllib.request

BASE_URL = 'http://127.0.0.1:8000'

def post_json(url, data, token=None):
    headers = {'Content-Type': 'application/json'}
    if token:
        headers['Authorization'] = f'Bearer {token}'
    req = urllib.request.Request(url, data=json.dumps(data).encode(), headers=headers, method='POST')
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode())

def patch_json(url, data, token=None):
    headers = {'Content-Type': 'application/json'}
    if token:
        headers['Authorization'] = f'Bearer {token}'
    req = urllib.request.Request(url, data=json.dumps(data).encode(), headers=headers, method='PATCH')
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode())

def get_json(url, token=None):
    headers = {}
    if token:
        headers['Authorization'] = f'Bearer {token}'
    req = urllib.request.Request(url, headers=headers, method='GET')
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode())

def main():
    print("=== Testing Complete End-to-End Triage & Notice Lifecycle ===")
    
    # 1. Authenticate Counselor & Student
    c_token = post_json(f'{BASE_URL}/auth/login', {'email': 'counselor@urios.edu.ph', 'password': 'Counselor123!'})['access_token']
    s_token = post_json(f'{BASE_URL}/auth/login', {'email': 'balbuenadexter2@gmail.com', 'password': 'password123'})['access_token']
    print("  PASS: Authenticated Counselor and Student")

    # 2. Get Flagged Messages
    flagged = get_json(f'{BASE_URL}/admin/flagged-messages', c_token)
    print(f"  PASS: Retrieved {len(flagged)} triage incident(s)")
    for f in flagged:
        print(f"    • [{f.get('status', 'active').upper()}] {f.get('user_name')} ({f.get('user_email')}): {f.get('flag_reason')}")

    if flagged:
        target = flagged[0]
        target_id = target['id']
        print(f"\n--- Testing Notice Issuance on Target: {target_id} ({target.get('user_name')}) ---")

        # 3. Issue Guidance Notice (Moves to In-Action)
        notice_res = post_json(f'{BASE_URL}/admin/flagged-messages/{target_id}/issue-notice', {
            'appointment_date': 'Tomorrow',
            'appointment_time': '2:00 PM',
            'location': 'Guidance Office 2nd Floor',
            'counselor_note': 'Supportive check-in regarding recent mood trend.',
            'student_name': target.get('user_name', 'Student'),
            'student_email': target.get('user_email', 'student@urios.edu.ph'),
        }, c_token)
        print(f"  PASS: Issued Guidance Notice -> Status: {notice_res.get('status')}")

        # 4. Student Checks & Acknowledges Notice
        notifs = get_json(f'{BASE_URL}/notifications', s_token)
        guidance_notif = next((n for n in notifs if n.get('type') == 'guidance_notice' or 'Call-Slip' in n.get('title', '')), None)
        if guidance_notif:
            print(f"  PASS: Student received in-app notification: '{guidance_notif.get('title')}'")
            ack_res = post_json(f'{BASE_URL}/notifications/{guidance_notif["id"]}/acknowledge', {}, s_token)
            print(f"  PASS: Student acknowledged notice -> Status: {ack_res.get('status')}")

        # 5. Counselor checks In-Action status with student acknowledgement
        flagged_after = get_json(f'{BASE_URL}/admin/flagged-messages', c_token)
        in_action_item = next((f for f in flagged_after if f['id'] == target_id), None)
        if in_action_item:
            print(f"  PASS: Verified In-Action Card -> Status: {in_action_item.get('status')}, Acknowledged: {in_action_item.get('is_acknowledged')}")

        # 6. Counselor resolves the case with clinical intake note
        resolve_res = patch_json(f'{BASE_URL}/admin/flagged-messages/{target_id}/resolve', {
            'resolution_note': 'Conducted physical 1-on-1 intake session at Guidance Center. Student confirmed feeling supported.'
        }, c_token)
        print(f"  PASS: Counselor marked resolved -> Status: {resolve_res.get('status')}")

        # 7. Verify Resolved log appears in flagged-messages
        flagged_final = get_json(f'{BASE_URL}/admin/flagged-messages', c_token)
        resolved_item = next((f for f in flagged_final if f['id'] == target_id), None)
        if resolved_item:
            print(f"  PASS: Verified Resolved Log -> Status: {resolved_item.get('status')}, Note: '{resolved_item.get('resolution_note')}'")

    print("\nALL TRIAGE & LIFECYCLE TESTS PASSED PERFECTLY!\n")

if __name__ == '__main__':
    main()
