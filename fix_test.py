with open('api-backend/app.test.js') as f:
    content = f.read()
content = content.replace("require('./app')", "require('./index')")
with open('api-backend/app.test.js', 'w') as f:
    f.write(content)
print('OK')
