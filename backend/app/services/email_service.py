import logging
import httpx
from typing import Optional
from app.core.config import settings

logger = logging.getLogger(__name__)


def send_guidance_call_slip_email(
    to_email: str,
    to_name: str,
    counselor_name: str,
    appointment_date: str = "Flexible / Walk-in",
    appointment_time: str = "Office Hours (8:00 AM - 5:00 PM)",
    location: str = "Urios Guidance & Counseling Center (Main Campus, 2nd Floor)",
    message: str = "Please visit the Guidance Center for a supportive, confidential 1-on-1 check-in.",
    urgency: str = "Priority Guidance Consultation",
    subject: Optional[str] = None,
) -> bool:
    """
    Send an official Father Saturnino Urios University (Urios) Guidance Call-Slip / 
    Physical Consultation Notice to the student's email via Brevo API.
    """
    if not settings.BREVO_API_KEY or not settings.BREVO_SENDER_EMAIL:
        logger.info(f"Brevo API key not configured — skipping email dispatch to {to_email}")
        return False

    email_subject = subject.strip() if subject and subject.strip() else f"🏛️ Guidance Office Consultation Call-Slip — {to_name}"

    html_body = f"""
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <style>
        body {{ font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #F8FAFC; margin: 0; padding: 20px; }}
        .card {{ max-width: 560px; margin: auto; background: #FFFFFF; border-radius: 16px; border: 1px solid #E2E8F0; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.05); }}
        .header {{ background: linear-gradient(135deg, #0284C7 0%, #0369A1 100%); padding: 28px; text-align: center; color: white; }}
        .content {{ padding: 28px 32px; color: #1E293B; }}
        .badge {{ display: inline-block; background: #FEF2F2; color: #DC2626; border: 1px solid #FCA5A5; font-size: 12px; font-weight: 700; padding: 4px 12px; border-radius: 9999px; text-transform: uppercase; margin-bottom: 12px; }}
        .info-box {{ background: #F0F9FF; border-left: 4px solid #0284C7; border-radius: 8px; padding: 18px; margin: 20px 0; }}
        .info-row {{ margin-bottom: 8px; font-size: 14px; }}
        .info-label {{ font-weight: 700; color: #0369A1; }}
        .message-box {{ background: #F8FAFC; border: 1px solid #E2E8F0; border-radius: 8px; padding: 16px; margin-top: 16px; font-style: italic; color: #475569; }}
        .footer {{ background: #F1F5F9; padding: 16px; text-align: center; font-size: 12px; color: #64748B; border-top: 1px solid #E2E8F0; }}
      </style>
    </head>
    <body>
      <div class="card">
        <div class="header">
          <h2 style="margin:0;font-size:20px;letter-spacing:0.5px;">🏛️ Father Saturnino Urios University</h2>
          <p style="margin:6px 0 0;font-size:13px;opacity:0.9;">Guidance & Counseling Center · Main Campus</p>
        </div>
        <div class="content">
          <div class="badge">{urgency}</div>
          <h3 style="margin-top:0;color:#0F172A;font-size:18px;">Official Guidance Consultation Notice</h3>
          
          <p>Dear <strong>{to_name}</strong>,</p>
          
          <p style="line-height:1.6;color:#334155;">
            You have received an official consultation message from the Urios Guidance & Counseling Center. We are here to provide a safe, supportive, and completely confidential space for you.
          </p>

          <div class="info-box">
            <div class="info-row"><span class="info-label">📍 Office Location:</span> {location}</div>
            <div class="info-row"><span class="info-label">📅 Consultation Date:</span> {appointment_date}</div>
            <div class="info-row"><span class="info-label">⏰ Preferred Time:</span> {appointment_time}</div>
            <div class="info-row"><span class="info-label">👤 Counselor:</span> {counselor_name}</div>
          </div>

          <p style="font-weight:600;margin-bottom:4px;color:#0F172A;">Counselor's Message:</p>
          <div class="message-box">
            "{message}"
          </div>

          <p style="margin-top:24px;font-size:13px;line-height:1.5;color:#64748B;">
            Please open the <strong>Kausap AI</strong> mobile app on your dashboard to view full details and confirm your visit.
          </p>
        </div>
        <div class="footer">
          <p style="margin:0;">Father Saturnino Urios University · Butuan City, Agusan del Norte</p>
          <p style="margin:4px 0 0;">Confidential & Protected Guidance Communication</p>
        </div>
      </div>
    </body>
    </html>
    """

    payload = {
        "sender": {
            "name": f"Urios Guidance Center ({settings.BREVO_SENDER_NAME})",
            "email": settings.BREVO_SENDER_EMAIL,
        },
        "to": [{"email": to_email, "name": to_name}],
        "subject": email_subject,
        "htmlContent": html_body,
    }

    try:
        response = httpx.post(
            "https://api.brevo.com/v3/smtp/email",
            json=payload,
            headers={
                "accept": "application/json",
                "api-key": settings.BREVO_API_KEY,
                "content-type": "application/json",
            },
            timeout=15,
        )
        if response.status_code in (200, 201):
            logger.info(f"✅ Brevo: Guidance Call-Slip email successfully sent to {to_email}")
            return True
        else:
            logger.warning(f"⚠️ Brevo API error {response.status_code}: {response.text}")
            return False
    except Exception as e:
        logger.error(f"Failed to send Brevo call-slip email to {to_email}: {e}")
        return False
