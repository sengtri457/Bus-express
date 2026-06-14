import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseAdmin = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
)

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')!

function generateCode(): string {
  return Math.floor(100000 + Math.random() * 900000).toString()
}

function generatePassword(): string {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
  let password = ''
  for (let i = 0; i < 16; i++) {
    password += chars.charAt(Math.floor(Math.random() * chars.length))
  }
  return password
}

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  try {
    const { email } = await req.json()

    if (!email || !email.includes('@')) {
      return new Response(JSON.stringify({ error: 'Invalid email' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const code = generateCode()
    const password = generatePassword()
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000).toISOString()

    // Delete any existing unused codes for this email
    await supabaseAdmin.from('otp_codes').delete().eq('email', email).eq('used', false)

    // Insert new code
    const { error: insertError } = await supabaseAdmin.from('otp_codes').insert({
      email,
      code,
      password,
      expires_at: expiresAt,
    })

    if (insertError) throw insertError

    // Send email via Resend
    await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${RESEND_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: 'BusExpress <onboarding@resend.dev>',
        to: email,
        subject: 'Your verification code',
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto;">
            <h2 style="color: #1E293B;">Verify your email</h2>
            <p style="color: #64748B;">Use the code below to sign in to <strong>BusExpress</strong>:</p>
            <div style="background: #F1F5F9; border-radius: 12px; padding: 24px; text-align: center; margin: 24px 0;">
              <span style="font-size: 36px; font-weight: 700; letter-spacing: 8px; color: #2563EB;">${code}</span>
            </div>
            <p style="color: #94A3B8; font-size: 13px;">This code expires in 5 minutes.</p>
            <hr style="border: none; border-top: 1px solid #E2E8F0; margin: 24px 0;" />
            <p style="color: #94A3B8; font-size: 12px;">
              If you didn't request this code, you can safely ignore this email.
            </p>
          </div>
        `,
      }),
    })

    return new Response(JSON.stringify({ success: true }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (error) {
    console.error('send-otp error:', error)
    return new Response(JSON.stringify({ error: 'Failed to send OTP' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
