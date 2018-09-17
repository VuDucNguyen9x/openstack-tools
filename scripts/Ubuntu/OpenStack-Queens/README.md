# Openstack-Queens-5node
Script dùng để cài đặt openstack queens mô hình 5 node trên Ubuntu 16.04 LTS

![](./images/Queens-5-node.png)

## Thực hiện cài đặt
Lưu ý: Các thông tin cấu hình ở trong file config.cfg

Tải script về cho tất cả các node

```
apt -y install git curl vim
git clone https://github.com/VuDucNguyen9x/openstack-tools.git

mv openstack-tools/scripts/Ubuntu/OpenStack-Queens/ ./queens/
cd queens/  && chmod +x *
```
Sửa các thông số trong file `config.cfg`

## 1. Đặt IP theo IP Planning cho từng node.

`Lưu ý:` Sau khi cài đặt địa chỉ ip xong, server sẽ thay đổi địa chỉ ip như trong file `config.cfg`. Đăng nhập lại vào server, cd đến thư mục queens và thực hiện các bước tiếp theo. Cũng có thể thực hiện thông qua việc ssh đến server để thực hiện các bước tiếp theo.

### Thực hiện trên Controller
- Thực thi script để thiết lập IP và hostname

```
./ctl_00_setup_ip.sh
```

### Thực hiện trên Compute
- Thực thi script để thiết lập IP và hostname

```
./com_00_setup_ip.sh
```

### Thực hiện trên Block (cinder)
- Thực thi script để thiết lập IP và hostname

```
./block_00_setup_ip.sh
```

### Thực hiện trên Object1 (Swift)
- Thực thi script để thiết lập IP và hostname

```
./object1_00_setup_ip.sh
```

### Thực hiện trên Object2 (Swift)
- Thực thi script để thiết lập IP và hostname

```
./object2_00_setup_ip.sh
```

## 2. Thực hiện script cài đặt OpenStack
### 2.1. Thực thi các script cài đặt trên controller

- Đứng trên node CTL và thực hiện các bước dưới.
- Thực thi script cài đặt các gói bổ trợ trên node controller

```
./ctl_01_environment.sh
```

- Thực thi script cài đặt keystone trên controller

```
./ctl_02_keystone.sh
```

Sau khi chạy xong script cài đặt keystone, script sẽ sinh ra các file tại `/root/admin-openrc` dùng để xác thực với OpenStack, sử dụng lệnh dưới mỗi khi thao tác với openstack thông qua CLI.

```
. admin-openrc
```

- Thực thi script cài đặt glance trên controller

```
./ctl_03_glance.sh
```

- Thực thi script cài đặt nova trên controller

```
./ctl_04_nova.sh
```

- Thực thi script cài đặt neutron trên controller

```
./ctl_05_neutron.sh
```

- Thực thi script cài đặt horizon trên controller

```
./ctl_06_horizon.sh
```

Lúc này có thể truy cập vào địa chỉ: `http://192.168.10.127/horizon` với Domain là `Default`, User là `admin`, mật khẩu là `admin123` (hoặc xem thêm file `/root/admin-openrc` để biết thêm). 

- Thực thi script cài đặt cinder trên controller

```
./ctl_07_cinder.sh
```

- Thực thi script cài đặt swift trên controller

```
./ctl_08_swift.sh
```

### 2.2. Thực thi các script cài đặt trên Compute

- Đứng trên node COM và thực hiện các bước dưới.
- Thực thi script cài đặt nova trên compute

```
./com_02_nova.sh
```

- Thực thi script cài đặt nova trên compute

```
./com_03_neutron.sh
```

### 2.3. Thực thi các script cài đặt trên Block

- Đứng trên node BLOCK và thực hiện các bước dưới.
- Thực thi script cài đặt cinder trên Block

```
./block_02_volume.sh
```

### 2.4. Thực hiện cài đặt trên Block
#### 2.4.1. Thực thi các script cài đặt trên object1
- Đứng trên node OBJECT1 và thực hiện các bước dưới.
- Thực thi script cài đặt swift trên object1

```
./object1_02_swift.sh
```

#### 2.4.2. Thực thi các script cài đặt trên object2
- Đứng trên node OBJECT1 và thực hiện các bước dưới.
- Thực thi script cài đặt swift trên object2

```
./object2_02_swift.sh
```


THANK YOU ^_^
