

既然你使用的是 **Cloudflare 的证书服务**，那你有两种常见的方式可以配置 HTTPS 证书，取决于你在 Cloudflare 的 **SSL/TLS 模式设置**：

---

## 🔒 一、推荐模式：「**Full（完全）模式** 或 Full (Strict)\*\*」

Cloudflare 支持你在 **源站（即 Nginx）使用 Cloudflare 提供的证书**，而不是 Let's Encrypt。这种模式下：

* 用户 → Cloudflare（HTTPS）
* Cloudflare → Nginx（HTTPS，使用 Cloudflare 提供的**源站证书**）

---

### ✅ 1. 获取 Cloudflare 源站证书

登录 Cloudflare 后：

**路径：**
`网站 > SSL/TLS > 源服务器 > 创建证书`

选择：

* 公钥类型：RSA
* 有效期：15 年或默认值
* 域名：填你的域名（如 `example.com` 和 `*.example.com`）
* 点击「创建证书」后，会得到：

> - 一个私钥（`origin.key`）
> - 一个证书（`origin.crt`）

保存成两个文件：

* `ssl/origin.crt`
* `ssl/origin.key`

---

### ✅ 2. Nginx 配置使用 Cloudflare 证书

在你的 `nginx.conf` 中这样写：

```nginx
server {
    listen 443 ssl;
    server_name example.com;

    ssl_certificate     /etc/nginx/ssl/origin.crt;
    ssl_certificate_key /etc/nginx/ssl/origin.key;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://wordpress:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

确保这两个文件在你容器里的 `/etc/nginx/ssl` 路径存在。

---

### ✅ 3. docker-compose 相关修改

如果使用的是docker容器的话，你需要在 `docker-compose.yml` 文件中添加以下内容：

你需要挂载证书目录到 nginx 容器中：

```yaml
  nginx:
    image: nginx:latest
    ports:
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    depends_on:
      - wordpress
```

---

## ⚠️ Cloudflare 额外注意事项

### Cloudflare 后台 → SSL/TLS → 设置应为：

| 模式                | 是否推荐                  |
| ----------------- | --------------------- |
| Flexible          | ❌ 不推荐，会导致回源明文连接（http） |
| **Full**          | ✅ 推荐，如果你没使用受信任 CA     |
| **Full (Strict)** | ✅ 推荐，最安全，需要有效证书       |

---

## ✅ 选项二：简单模式 + Nginx 明文

如果你使用的是 Cloudflare 的「Flexible」模式（不推荐），你可以不配置 nginx https，Nginx 直接监听 80，Cloudflare 会自动把外部的 HTTPS 请求转成 HTTP 请求访问你的 Nginx。但这种方式存在中间人攻击风险。

---

## 💡总结

| 场景                   | 推荐做法                        |
| -------------------- | --------------------------- |
| 使用 Cloudflare 全站代理   | 用 Cloudflare 的源站证书配置 nginx  |
| 配合 docker-compose 部署 | 把证书文件挂载到 nginx 容器           |
| Cloudflare SSL 模式    | **Full 或 Full (Strict)** 模式 |
| 是否要使用 Let's Encrypt  | 不需要，Cloudflare 的证书即可        |

---


## 📁 项目结构建议

```
wordpress-ssl-docker/
├── docker-compose.yml
├── nginx/
│   ├── wordpress.conf          # HTTP 转 HTTPS 跳转
│   ├── wordpress-ssl.conf      # HTTPS 代理配置
│   └── ssl/
│       ├── origin.crt          # Cloudflare 颁发的证书
│       └── origin.key          # Cloudflare 颁发的私钥
└── upload.ini                  # PHP 上传限制
```

---

## 📦 `docker-compose.yml`

**推荐**

```yaml
version: '3.3'
services:
   db:
     image: mysql:5.7
     volumes:
       - db_data:/var/lib/mysql
     restart: always
     environment:
       MYSQL_ROOT_PASSWORD: somewordpress
       MYSQL_DATABASE: wordpress
       MYSQL_USER: wordpress
       MYSQL_PASSWORD: wordpress
   wordpress:
     depends_on:
       - db
     image: wordpress:latest
     ports:
       - "8080:80"
     restart: always
     environment:
       WORDPRESS_DB_HOST: db:3306
       WORDPRESS_DB_USER: wordpress
       WORDPRESS_DB_PASSWORD: wordpress
       WORDPRESS_DB_NAME: wordpress
     volumes:
       - ./upload.ini:/usr/local/etc/php/conf.d/uploads.ini
volumes:
   db_data: {}


```

**不推荐**

```yaml
version: '3.3'

services:
  db:
    image: mysql:5.7
    volumes:
      - db_data:/var/lib/mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: somewordpress
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress

  wordpress:
    depends_on:
      - db
    image: wordpress:latest
    expose:
      - "80"
    restart: always
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpress
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - ./upload.ini:/usr/local/etc/php/conf.d/uploads.ini

  nginx:
    image: nginx:latest
    depends_on:
      - wordpress
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/wordpress.conf:/etc/nginx/conf.d/wordpress.conf:ro
      - ./nginx/wordpress-ssl.conf:/etc/nginx/conf.d/wordpress-ssl.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro

volumes:
  db_data: {}
```

---

## 🌐 `nginx/wordpress.conf` （HTTP → HTTPS 跳转）

```nginx
server {
    listen 80;
    server_name yourdomain.com;

    return 301 https://$host$request_uri;
}
```

---

## 🔒 `nginx/wordpress-ssl.conf` （HTTPS + Cloudflare 源站证书）

```nginx
server {
    listen 443 ssl;
    server_name yourdomain.com;

    ssl_certificate     /etc/nginx/ssl/origin.crt;
    ssl_certificate_key /etc/nginx/ssl/origin.key;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

> 替换 `yourdomain.com` 为你绑定到 Cloudflare 的域名。

---

## 📝 `upload.ini` 示例

```ini
file_uploads = On
memory_limit = 256M
upload_max_filesize = 64M
post_max_size = 64M
```

---

## 📥 证书放置方式

将 Cloudflare 创建源站证书时生成的内容：

* 公钥（证书）保存为：`nginx/ssl/origin.crt`
* 私钥保存为：`nginx/ssl/origin.key`

**确保两个文件都有权限被 nginx 容器读取。**

---

## 🚀 启动命令

```bash
docker compose up -d
```

---

## ✅ 验证步骤

1. 本地 `curl -I https://yourdomain.com` 应返回 200 或 301。
2. 浏览器访问，资源无裂图。
3. WordPress 后台地址：`https://yourdomain.com/wp-admin/`

---

## 🔧（可选）WordPress 设置强制使用 HTTPS

在 `wp-config.php` 中加入：

```php
define('WP_HOME', 'https://yourdomain.com');
define('WP_SITEURL', 'https://yourdomain.com');
```

---

如需我打包为 zip 或脚本下载、或扩展为支持自动更新 Cloudflare 源站证书、Let's Encrypt 等，请告诉我。需要我生成 `.zip` 吗？
