with open('api-backend/index.js') as f:
    content = f.read()

content = content.replace('    process.exit(1);', '    // process.exit(1);')

ssl_old = '  ssl: {\n    rejectUnauthorized: false\n  }'
ssl_new = "  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false"
content = content.replace(ssl_old, ssl_new)

with open('api-backend/index.js', 'w') as f:
    f.write(content)
print('OK')
