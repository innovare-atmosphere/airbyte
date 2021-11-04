server {
    server_name ${ server_name };
    client_max_body_size 20M;
    location / {
	proxy_set_header        Host               $host;
        proxy_set_header        X-Forwarded-For    $proxy_add_x_forwarded_for;
        proxy_set_header        X-Forwarded-Proto  $scheme;

        # drop unused proxy headers to prevent clients from tampering with them
        proxy_set_header        X-Forwarded-Port   "";
        proxy_set_header        Forwarded   "";
        proxy_set_header        X-Real-IP   "";
        proxy_set_header        X-Forwarded-Host "";
        proxy_pass http://localhost:8000/;
    }


    listen 80; # managed by Certbot
}