# game服务器镜像

可以使用环境变量进行配置

| 环境变量名称     | 说明                       | 默认值    |
| ---------------- | -------------------------- | --------- |
| GAME_SERVER_IP   | 游戏服务器的公网IP         | 127.0.0.1 |
| GAME_SERVER_PORT | 游戏端口                   | 3731      |
| DB_HOST          | 数据库服务器的主机名或者IP | db_server |
| DB_PORT          | 数据库端口                 | 3306      |
| DB_USERNAME      | 数据库用户名               | root      |
| DB_PASSWORD      | 数据库密码                 | root      |
| DB_GAME_NAME     | 游戏数据库名称             | tlbbdb    |
| DB_ACCOUNT_NAME  | 账号数据库名称             | web       |
| SMU_INTERVAL     | world数据存盘时间（毫秒）  | 1200000   |
| DATA_INTERVAL    | Human数据存盘时间(毫秒）   | 900000    |
| WITH_GAME_LOG    | 是否记录服务端日志文件     | yes       |

此镜像自带billing程序，如果你需要使用外部的billing，可以配置以下环境变量

| 环境变量名称        | 说明               | 默认值    |
| ------------------- | ------------------ | --------- |
| BILLING_SERVER_IP   | 外部billing IP地址 | 127.0.0.1 |
| BILLING_SERVER_PORT | 外部billing端口    | 12680     |

服务器需要映射两个端口

- 7384 登录端口
- 3731(GAME_SERVER_PORT环境变量) 游戏端口

