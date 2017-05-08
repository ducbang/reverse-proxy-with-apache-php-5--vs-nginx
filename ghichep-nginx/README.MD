## Ghi chép về nginx

### 1. Server Block - Virtual host

Trong file cấu hình của nginx, chúng ta thêm một hoặc nhiều server block bên trong khối `http` như sau:

```
server {
        listen 80;
		
        server_name test.com www.test.com;
		
		access_log /var/log/nginx/test.com.acc-log combined;
		error_log /var/log/nginx/test.com.err-log;
		
        location / {
			proxy_pass http://proxy.example.com;
        }
}
```

- Giải thích:
	- `listen 80`: Port lắng nghe của nginx
	- `server_name`: Domain lắng nghe
	- `access_log`: Log ghi lại những hành động truy cập
	- `error_log`: Log ghi lại những hành động lỗi
	- `proxy_pass`: Làm proxy trung gian giữa người dùng và 1 trang khác. Tùy chọn này khác với `redirect 301` sẽ chuyển thẳng người dùng sang trang đó.