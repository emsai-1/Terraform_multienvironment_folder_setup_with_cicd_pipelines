#!/bin/bash
# This script is run on instance startup

# Update packages and install a simple Apache web server
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd

# --- REPLACE THE OLD ECHO LINE WITH THIS ENTIRE BLOCK ---
echo '
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>A Special Message For You</title>
    <style>
        body {
            background: linear-gradient(135deg, #4a00e0, #8e2de2);
            font-family: "Segoe UI", Roboto, "Helvetica Neue", sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            color: #fff;
        }
        .container {
            background: rgba(0, 0, 0, 0.4);
            padding: 50px;
            border-radius: 20px;
            box-shadow: 0 15px 30px rgba(0,0,0,0.3);
            text-align: center;
            max-width: 800px;
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        h1 {
            color: #f8cdda; /* Soft Pink */
            font-size: 2.5em;
            margin-bottom: 20px;
        }
        p {
            font-size: 1.4em;
            line-height: 1.6;
            color: #e0e0e0;
        }
        .highlight {
            color: #fff8b2; /* Soft Yellow */
            font-weight: bold;
            font-size: 1.8em;
            display: block;
            margin: 30px 0;
        }
        .relax {
            font-size: 3em;
            font-weight: bold;
            color: #00e676; /* Bright Green */
            animation: glow 2s ease-in-out infinite;
        }
        footer {
            margin-top: 40px;
            font-size: 0.8em;
            color: #aaa;
        }
        /* The glowing animation for the "Relax" text */
        @keyframes glow {
            0%, 100% {
                text-shadow: 0 0 10px #00e676, 0 0 20px #00e676, 0 0 30px #00e676;
            }
            50% {
                text-shadow: 0 0 20px #00e676, 0 0 40px #00e676, 0 0 60px #00e676;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>To My Amazing Girlfriend,</h1>
        <p>
            I know you work incredibly hard, so I deployed this little server across the cloud, just to deliver this message to you.
        </p>
        <p class="highlight">
            Please take some time to rest and relax today.
        </p>
        <p>
            Enjoy the weekend. You deserve every moment of peace and happiness.
        </p>
        <div class="relax">
            Relaxxxxxxx! ❤️
        </div>
        <footer>This message was deployed with love from the ${environment} environment.</footer>
    </div>
</body>
</html>
' > /var/www/html/index.html

