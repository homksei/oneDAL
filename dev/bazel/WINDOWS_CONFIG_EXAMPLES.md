# Windows Configuration Examples

Этот документ содержит примеры конфигураций для различных сценариев использования oneDAL на Windows.

## Базовые конфигурации

### Разработка с Visual Studio Community
```cmd
@echo off
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x64
bazel build @onedal//:release --config=win-msvc -c dbg
```

### Производственная сборка с MSVC
```cmd
@echo off
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvarsall.bat" x64
bazel build @onedal//:release --config=win-msvc -c opt --cpu=avx2 --backend_config=mkl
```

### Сборка с Intel oneAPI
```cmd
@echo off
call "C:\Program Files (x86)\Intel\oneAPI\setvars.bat"
set CC=icx
bazel build @onedal//:release --config=win-icx --cpu=avx512 --backend_config=mkl
```

## Конfigurации для разных процессоров

### Intel CPU с AVX-512
```cmd
bazel build @onedal//:release --config=win-icx --cpu=avx512 --features=avx512
```

### Старые процессоры (SSE2)
```cmd
bazel build @onedal//:release --config=win-msvc --cpu=sse2
```

### Современные процессоры (AVX2)
```cmd
bazel build @onedal//:release --config=win-msvc --cpu=avx2
```

## Конфигурации для разработки

### Debug сборка с символами отладки
```cmd
bazel build @onedal//:release --config=win-msvc -c dbg --copt=/Zi --linkopt=/DEBUG:FULL
```

### Быстрая инкрементальная сборка
```cmd
bazel build @onedal//:release --config=win-msvc --jobs=4 --disk_cache=C:\bazel-cache
```

### Сборка только публичного API
```cmd
bazel build @onedal//:release --config=win-msvc --config=public
```

## Конфигурации для тестирования

### Запуск всех тестов
```cmd
bazel test //cpp/... --config=win-msvc --test_output=errors
```

### Запуск только host (CPU) тестов
```cmd
bazel test //cpp/... --config=win-msvc --config=host
```

### Запуск тестов с подробным выводом
```cmd
bazel test //cpp/... --config=win-msvc --test_output=all --test_verbose_timeout_warnings
```

### Запуск конкретного теста
```cmd
bazel test //cpp/oneapi/dal:array_test --config=win-msvc
```

## GPU и DPC++ конфигурации

### Сборка с DPC++ для GPU
```cmd
@echo off
call "C:\Program Files (x86)\Intel\oneAPI\setvars.bat"
set CC=icpx
bazel build @onedal//:release --config=win-icpx --features=dpc++ --device=gpu
```

### Сборка только для CPU с DPC++
```cmd
@echo off
call "C:\Program Files (x86)\Intel\oneAPI\setvars.bat"
set CC=icpx
bazel build @onedal//:release --config=win-icpx --features=dpc++ --device=cpu
```

### Тестирование DPC++ функциональности
```cmd
bazel test //cpp/... --config=win-icpx --config=dpc --test_env=SYCL_DEVICE_FILTER=opencl
```

## Специальные конфигурации

### Сборка с MKL backend
```cmd
bazel build @onedal//:release --config=win-icx --backend_config=mkl
```

### Сборка с Reference backend
```cmd
bazel build @onedal//:release --config=win-msvc --backend_config=ref
```

### Статическая сборка
```cmd
bazel build @onedal//:release --config=win-msvc --test_link_mode=static
```

### Динамическая сборка
```cmd
bazel build @onedal//:release --config=win-msvc --test_link_mode=dynamic
```

## CI/CD конфигурации

### Автоматическая сборка в GitHub Actions
```yaml
# .github/workflows/windows-build.yml
name: Windows Build
on: [push, pull_request]
jobs:
  build:
    runs-on: windows-latest
    steps:
    - uses: actions/checkout@v3
    - name: Setup MSVC
      uses: microsoft/setup-msbuild@v1
    - name: Build oneDAL
      run: |
        call "C:\Program Files (x86)\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvarsall.bat" x64
        bazel build @onedal//:release --config=win-msvc
```

### Jenkins Pipeline
```groovy
pipeline {
    agent { label 'windows' }
    stages {
        stage('Build') {
            steps {
                bat '''
                call "C:\\Program Files (x86)\\Microsoft Visual Studio\\2022\\Professional\\VC\\Auxiliary\\Build\\vcvarsall.bat" x64
                bazel build @onedal//:release --config=win-msvc --cpu=avx2
                '''
            }
        }
        stage('Test') {
            steps {
                bat '''
                bazel test //cpp/... --config=win-msvc --test_output=errors
                '''
            }
        }
    }
}
```

## Оптимизация сборки

### Использование удаленного кэша
```cmd
bazel build @onedal//:release --config=win-msvc --remote_cache=grpc://your-cache-server:9092
```

### Ограничение использования памяти
```cmd
bazel build @onedal//:release --config=win-msvc --local_ram_resources=8192
```

### Параллельная сборка
```cmd
bazel build @onedal//:release --config=win-msvc --jobs=8 --local_cpu_resources=8
```

### Локальный дисковый кэш
```cmd
bazel build @onedal//:release --config=win-msvc --disk_cache=C:\bazel-cache
```

## Интеграция с IDE

### Visual Studio Code
```json
// .vscode/tasks.json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Build oneDAL Release",
            "type": "shell",
            "command": "bazel",
            "args": ["build", "@onedal//:release", "--config=win-msvc"],
            "group": "build",
            "options": {
                "env": {
                    "INCLUDE": "${env:INCLUDE}",
                    "LIB": "${env:LIB}",
                    "PATH": "${env:PATH}"
                }
            }
        },
        {
            "label": "Run Tests",
            "type": "shell",
            "command": "bazel",
            "args": ["test", "//cpp/...", "--config=win-msvc"],
            "group": "test"
        }
    ]
}
```

### CLion with Bazel Plugin
```python
# .bazelproject
targets:
  @onedal//:release
  //cpp/...
  //examples/...

additional_languages:
  c++

build_flags:
  --config=win-msvc
  --cpu=avx2
```

## Устранение неполадок

### Проблемы с памятью
```cmd
# Ограничить использование памяти
bazel build @onedal//:release --config=win-msvc --local_ram_resources=4096 --jobs=2
```

### Проблемы с путями
```cmd
# Использовать короткие пути
bazel build @onedal//:release --config=win-msvc --output_user_root=C:\b
```

### Проблемы с антивирусом
```cmd
# Исключить директории из антивирусного сканирования:
# - C:\Users\<user>\_bazel_<user>
# - <workspace>\bazel-*
# - C:\bazel-cache (если используется)
```

### Проблемы с правами доступа
```cmd
# Запуск от имени администратора может потребоваться для:
# - Первой сборки
# - После обновления Visual Studio
# - При проблемах с symlinks
```

Эти конфигурации покрывают большинство сценариев использования oneDAL на Windows с Bazel.
