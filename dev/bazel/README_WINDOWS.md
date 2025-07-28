# Windows Bazel Build Guide

Этот документ описывает, как собрать oneDAL на Windows с использованием Bazel.

## Требования к системе

### Минимальные требования
- Windows 10 или Windows 11
- Visual Studio 2019 или 2022 с C++ инструментами
- Bazel 6.0+
- Windows SDK 10

### Рекомендуемые требования
- Windows 11
- Visual Studio 2022 Professional/Enterprise
- Intel oneAPI Toolkit (для Intel компиляторов)
- 8GB+ RAM для сборки
- SSD для ускорения сборки

## Поддерживаемые компиляторы

### Microsoft Visual C++ (MSVC)
```cmd
# Установить переменные окружения Visual Studio
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x64

# Сборка с MSVC
bazel build @onedal//:release --config=win-msvc
```

### Intel C++ Compiler (icx)
```cmd
# Убедиться что Intel oneAPI установлен
call "C:\Program Files (x86)\Intel\oneAPI\setvars.bat"

# Сборка с Intel компилятором
set CC=icx
bazel build @onedal//:release --config=win-icx
```

### Intel DPC++ Compiler (icpx)
```cmd
# Убедиться что Intel oneAPI установлен
call "C:\Program Files (x86)\Intel\oneAPI\setvars.bat"

# Сборка с DPC++ для GPU поддержки
set CC=icpx
bazel build @onedal//:release --config=win-icpx
```

## Основные команды сборки

### Базовая сборка релиза
```cmd
bazel build @onedal//:release --config=win
```

### Сборка с конкретным компилятором
```cmd
# MSVC
bazel build @onedal//:release --config=win-msvc

# Intel ICX
bazel build @onedal//:release --config=win-icx

# Intel DPC++
bazel build @onedal//:release --config=win-icpx
```

### Сборка с CPU оптимизациями
```cmd
# AVX2 оптимизации
bazel build @onedal//:release --config=win --cpu=avx2

# AVX-512 оптимизации
bazel build @onedal//:release --config=win --cpu=avx512
```

### Тестирование
```cmd
# Запуск всех тестов
bazel test //cpp/... --config=win

# Запуск тестов только для host (CPU)
bazel test //cpp/... --config=win --config=host

# Запуск тестов для публичного API
bazel test //cpp/... --config=win --config=public
```

## Конфигурационные опции

### Backend конфигурация
```cmd
# Использование Intel MKL
bazel build @onedal//:release --config=win --backend_config=mkl

# Использование Reference backend
bazel build @onedal//:release --config=win --backend_config=ref
```

### Режимы сборки
```cmd
# Debug сборка
bazel build @onedal//:release --config=win -c dbg

# Optimized сборка (по умолчанию)
bazel build @onedal//:release --config=win -c opt
```

## Переменные окружения

### Обязательные
```cmd
# Для Visual Studio
set INCLUDE=C:\Program Files (x86)\Windows Kits\10\Include\10.0.19041.0\ucrt;C:\Program Files (x86)\Windows Kits\10\Include\10.0.19041.0\shared;...
set LIB=C:\Program Files (x86)\Windows Kits\10\Lib\10.0.19041.0\ucrt\x64;C:\Program Files (x86)\Windows Kits\10\Lib\10.0.19041.0\um\x64;...
```

### Опциональные
```cmd
# Для Intel компиляторов
set MKLROOT=C:\Program Files (x86)\Intel\oneAPI\mkl\latest
set TBBROOT=C:\Program Files (x86)\Intel\oneAPI\tbb\latest
set DPLROOT=C:\Program Files (x86)\Intel\oneAPI\dpl\latest

# Для MPI поддержки
set MPIROOT=C:\Program Files (x86)\Intel\oneAPI\mpi\latest

# Для тестирования
set DAAL_DATASETS=C:\path\to\datasets
```

## Примеры сборки

### Полная сборка с Intel oneAPI
```cmd
@echo off
call "C:\Program Files (x86)\Intel\oneAPI\setvars.bat"
set CC=icx
bazel build @onedal//:release --config=win-icx --backend_config=mkl --cpu=avx2
```

### Сборка для разработки
```cmd
@echo off
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x64
bazel build @onedal//:release --config=win-msvc -c dbg
```

### Сборка examples
```cmd
bazel build //examples/... --config=win
```

### Сборка samples
```cmd
bazel build //samples/... --config=win
```

## Устранение неполадок

### Общие проблемы

1. **Компилятор не найден**
   ```
   Error: Cannot find 'cl.exe' tool
   ```
   Решение: Запустить vcvarsall.bat перед сборкой

2. **Отсутствие Windows SDK**
   ```
   Error: Windows SDK not found
   ```
   Решение: Установить Windows SDK через Visual Studio Installer

3. **Недостаточно памяти**
   ```
   Error: Out of memory
   ```
   Решение: Увеличить виртуальную память или использовать --jobs=N

### Советы по производительности

1. **Использовать локальный кэш Bazel**
   ```cmd
   bazel build @onedal//:release --config=win --disk_cache=C:\bazel-cache
   ```

2. **Ограничить количество параллельных задач**
   ```cmd
   bazel build @onedal//:release --config=win --jobs=4
   ```

3. **Использовать удаленный кэш (если доступен)**
   ```cmd
   bazel build @onedal//:release --config=win --remote_cache=grpc://your-cache-server:9092
   ```

## Интеграция с IDE

### Visual Studio Code
1. Установить расширение Bazel
2. Открыть workspace oneDAL
3. Конфигурировать tasks.json:
   ```json
   {
     "version": "2.0.0",
     "tasks": [
       {
         "label": "Build oneDAL Windows",
         "type": "shell",
         "command": "bazel",
         "args": ["build", "@onedal//:release", "--config=win"],
         "group": "build"
       }
     ]
   }
   ```

### Visual Studio
1. Использовать Bazel для генерации solution файлов (если доступно)
2. Или использовать "Folder" проект для работы с исходным кодом

## Поддержка

При возникновении проблем:
1. Проверить переменные окружения
2. Убедиться в правильности установки компилятора
3. Проверить версию Bazel
4. Посмотреть логи сборки для деталей ошибок

Дополнительную информацию можно найти в:
- [oneDAL GitHub Issues](https://github.com/uxlfoundation/oneDAL/issues)
- [Intel oneAPI Documentation](https://www.intel.com/content/www/us/en/developer/tools/oneapi/documentation.html)
