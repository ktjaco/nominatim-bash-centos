A series of bash scripts to build Nominatim 2.3.1 on CentOS 6.7.

### 1. Clone GitHub repository
```
$ git clone https://github.com/ktjaco/nominatim-bash-centos
$ cd nominatim-bash-centos
```

### 2. Check permissions
```
$ sudo chmod +x build.sh
$ sudo chmod +x dependencies.sh
```

### 3. Install required dependencies
```
$ ./dependencies.sh
```

### 4. Build Nominatim 2.3.1
```
$ ./build.sh
```
