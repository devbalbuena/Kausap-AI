/// Centralized crisis fallback hotlines & clinical resolution presets for Kausap AI.
///
/// Shared across Counselor Triage, Admin Moderation, and Student Crisis Resources
/// so offline fallback contacts and clinical resolution actions stay synchronized.
class CrisisDefaults {
  CrisisDefaults._();

  static const List<Map<String, dynamic>> fallbackHotlines = [
    {
      "id": "fsuu-default-1",
      "name": "FSUU Guidance Center Emergency Line",
      "phone": "(085) 342-1830",
      "number": "(085) 342-1830",
      "email": "guidance@urios.edu.ph",
      "description": "Main Campus, Father Saturnino Urios University, Butuan City",
      "category": "campus",
      "type": "call",
      "is_active": true,
      "sort_order": 1,
    },
    {
      "id": "ncmh-default-2",
      "name": "National Center for Mental Health (NCMH)",
      "phone": "1553 / 0917-899-8727",
      "number": "1553",
      "email": "ncmh.gov.ph",
      "description": "24/7 National Mental Health Crisis Hotline (Toll-Free Nationwide)",
      "category": "national",
      "type": "call",
      "is_active": true,
      "sort_order": 2,
    },
    {
      "id": "hopeline-default-3",
      "name": "Hopeline Philippines",
      "phone": "0917-558-4673 / (02) 8804-4673",
      "number": "0917-558-4673",
      "email": "hopeline@ngf-hope.org",
      "description": "24/7 Suicide Prevention & Crisis Support Line",
      "category": "national",
      "type": "call",
      "is_active": true,
      "sort_order": 3,
    },
    {
      "id": "intouch-default-4",
      "name": "In Touch Community Services",
      "phone": "+63 917 800 1123 / +63 2 8893 7603",
      "number": "02-8893-7603",
      "email": "crisisline@in-touch.org",
      "description": "Crisis Line Philippines 24/7 Multilingual Support",
      "category": "national",
      "type": "call",
      "is_active": true,
      "sort_order": 4,
    },
    {
      "id": "911-default-5",
      "name": "Philippine Emergency Hotline (911)",
      "phone": "911",
      "number": "911",
      "email": null,
      "description": "National Emergency First Responders, Police & Ambulance",
      "category": "emergency",
      "type": "call",
      "is_active": true,
      "sort_order": 5,
    },
    {
      "id": "text-crisis-default-6",
      "name": "Text Crisis Support Line",
      "phone": "09178626820",
      "number": "09178626820",
      "email": null,
      "description": "Text HELLO to this number for confidential SMS chat support",
      "category": "national",
      "type": "sms",
      "is_active": true,
      "sort_order": 6,
    },
  ];

  static const List<String> clinicalActionPresets = [
    "Conducted physical 1-on-1 intake session at Guidance Center",
    "Completed in-person assessment & safety check-in",
    "Scheduled follow-up physical consultation with guidance staff",
    "Dispatched emergency contact & NCMH 1553 hotlines",
    "Referred to Student Affairs & Guidance testing center",
    "Reviewed context: False positive / safe emotional expression",
  ];
}
