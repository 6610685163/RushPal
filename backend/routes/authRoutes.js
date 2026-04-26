const express = require('express');
const axios = require('axios');
const admin = require('firebase-admin');
const router = express.Router();

// Facebook OAuth Config
const FACEBOOK_APP_ID = process.env.FACEBOOK_APP_ID;
const FACEBOOK_APP_SECRET = process.env.FACEBOOK_APP_SECRET;
const REDIRECT_URI = process.env.FACEBOOK_REDIRECT_URI || 'https://cn333-95dd5.firebaseapp.com/__/auth/handler';

// Facebook OAuth: Exchange Authorization Code for Access Token
router.post('/facebook', async (req, res) => {
  try {
    const { code } = req.body;

    if (!code) {
      return res.status(400).json({ error: 'Authorization code is required' });
    }

    if (!FACEBOOK_APP_ID || !FACEBOOK_APP_SECRET) {
      return res.status(500).json({ error: 'Facebook App credentials not configured' });
    }

    console.log('🔄 Exchanging Facebook code for access token...');

    // Step 1: Exchange code for access token
    const tokenResponse = await axios.get('https://graph.facebook.com/v18.0/oauth/access_token', {
      params: {
        client_id: FACEBOOK_APP_ID,
        client_secret: FACEBOOK_APP_SECRET,
        redirect_uri: REDIRECT_URI,
        code: code,
      },
    });

    const facebookAccessToken = tokenResponse.data.access_token;
    console.log('✅ Got Facebook Access Token');

    // Step 2: Get user info from Facebook
    const userResponse = await axios.get('https://graph.facebook.com/me', {
      params: {
        fields: 'id,name,email,picture',
        access_token: facebookAccessToken,
      },
    });

    const facebookUser = userResponse.data;
    console.log('👤 Facebook User:', facebookUser);

    // Step 3: Create Firebase Custom Token
    const customToken = await admin.auth().createCustomToken(facebookUser.id, {
      provider: 'facebook',
      email: facebookUser.email,
      name: facebookUser.name,
      picture: facebookUser.picture?.data?.url,
    });

    console.log('✅ Created Firebase Custom Token');

    // Step 4: Return custom token to app
    res.json({
      success: true,
      customToken: customToken,
      user: {
        id: facebookUser.id,
        email: facebookUser.email,
        name: facebookUser.name,
        picture: facebookUser.picture?.data?.url,
      },
    });
  } catch (error) {
    console.error('🚨 Facebook OAuth Error:', error.response?.data || error.message);
    res.status(500).json({
      error: 'Facebook authentication failed',
      details: error.response?.data || error.message,
    });
  }
});

module.exports = router;
