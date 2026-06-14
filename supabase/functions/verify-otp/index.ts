import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseAdmin = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
)

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  try {
    const { email, code } = await req.json()

    if (!email || !code) {
      return new Response(JSON.stringify({ error: 'Email and code are required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Find valid, unused, non-expired OTP
    const { data: otp, error: findError } = await supabaseAdmin
      .from('otp_codes')
      .select('*')
      .eq('email', email)
      .eq('code', code)
      .eq('used', false)
      .gte('expires_at', new Date().toISOString())
      .maybeSingle()

    if (findError) throw findError

    if (!otp) {
      return new Response(JSON.stringify({ error: 'Invalid or expired code' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Mark code as used
    await supabaseAdmin.from('otp_codes').update({ used: true }).eq('id', otp.id)

    // Check if user exists in auth.users
    const { data: { users } } = await supabaseAdmin.auth.admin.listUsers()
    const existingUser = users.find((u: any) => u.email === email)

    if (existingUser) {
      // Update password so client can sign in
      await supabaseAdmin.auth.admin.updateUserById(existingUser.id, {
        password: otp.password,
      })
    } else {
      // Create new user with confirmed email
      const { data: newUser, error: createError } =
        await supabaseAdmin.auth.admin.createUser({
          email,
          password: otp.password,
          email_confirm: true,
        })

      if (createError) throw createError

      // Also create entry in the public users table
      if (newUser?.user) {
        await supabaseAdmin.from('users').insert({
          id: newUser.user.id,
          email,
          name: email.split('@')[0],
          role: 'passenger',
          status: 'active',
        })
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        email,
        password: otp.password,
      }),
      {
        headers: { 'Content-Type': 'application/json' },
      },
    )
  } catch (error) {
    console.error('verify-otp error:', error)
    return new Response(JSON.stringify({ error: 'Verification failed' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
