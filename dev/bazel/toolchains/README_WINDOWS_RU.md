# Поддержка Windows для Bazel сборки oneDAL

Этот документ описывает добавление поддержки Windows в систему сборки oneDAL с использованием Bazel.

## Обзор

В oneDAL Bazel toolchain систему добавлена поддержка Windows, позволяющая сборку на Windows с использованием Microsoft Visual Studio (MSVC) или Intel oneAPI C++ Compiler (ICX).

## Добавленные/Изменённые файлы

### Новые файлы
- `dev/bazel/toolchains/cc_toolchain_config_win.bzl` - Конфигурация C++ toolchain для Windows
- `dev/bazel/toolchains/cc_toolchain_win.bzl` - Настройка Windows toolchain и поиск инструментов
- `dev/bazel/toolchains/cc_toolchain_win.tpl.BUILD` - BUILD шаблон для Windows toolchain
- `dev/bazel/toolchains/extra_toolchain_win.bzl` - Конфигурация дополнительного Windows toolchain
- `dev/bazel/toolchains/extra_toolchain_win.tpl.BUILD` - BUILD шаблон для дополнительного Windows toolchain
- `dev/bazel/toolchains/tools/merge_static_libs_win.tpl.bat` - Объединение статических библиотек для Windows
- `dev/bazel/toolchains/tools/dynamic_link_win.tpl.bat` - Обёртка для динамической линковки Windows
- `dev/bazel/toolchains/tools/patch_daal_kernel_defines.bat` - Патчер DAAL kernel defines для Windows
- `dev/bazel/toolchains/README_WINDOWS.md` - Подробная документация по Windows поддержке
- `dev/bazel/toolchains/test/` - Тестовые файлы для проверки Windows toolchain

### Изменённые файлы
- `dev/bazel/toolchains/cc_toolchain.bzl` - Добавлена поддержка Windows в основную конфигурацию toolchain
- `dev/bazel/toolchains/common.bzl` - Улучшено определение Windows компилятора
- `dev/bazel/toolchains/extra_toolchain.bzl` - Добавлена поддержка Windows в дополнительный toolchain
- `dev/bazel/toolchains/extra_toolchain_lnx.bzl` - Обновлён интерфейс для соответствия Windows версии

## Требования

### Visual Studio
- Visual Studio 2019 или новее с инструментами C++ сборки
- Или Visual Studio Build Tools 2019/2022

### Intel oneAPI (Опционально)
- Intel oneAPI DPC++/C++ Compiler для Windows
- Intel oneAPI Math Kernel Library (oneMKL)

## Использование

Windows toolchain автоматически определяется и настраивается при сборке на Windows. Система будет:

1. Определять операционную систему как Windows
2. Искать доступные компиляторы (ICX -> MSVC cl.exe)
3. Настраивать среду Visual Studio с помощью vcvarsall.bat
4. Устанавливать соответствующие флаги компиляции и линковки

### Переменные окружения

Следующие переменные окружения могут использоваться для настройки сборки:

- `CC` - Переопределить определение компилятора (например, `cl`, `icx`)
- `PATH` - Должен включать инструменты Visual Studio
- `INCLUDE` - Дополнительные каталоги включений
- `LIB` - Дополнительные каталоги библиотек

### Сборка

```bash
# Стандартная сборка (автоматически определит Windows toolchain)
bazel build //...

# Сборка с конкретным компилятором
set CC=icx
bazel build //...

# Сборка с отладочной конфигурацией
bazel build -c dbg //...

# Тестирование Windows toolchain
bazel build //dev/bazel/toolchains/test:hello_world_win
```

## Поддерживаемые компиляторы

1. **Microsoft Visual C++ (cl.exe)** - Компилятор Windows по умолчанию
   - Поддерживает стандарт C++17
   - Оптимизирован для разработки под Windows

2. **Intel oneAPI C++ Compiler (icx)** - Современный C++ компилятор Intel
   - Основан на LLVM/Clang
   - Лучшая оптимизация для оборудования Intel
   - Полная поддержка C++17

## Возможности

### Автоматический поиск инструментов
- Автоматически находит установку Visual Studio
- Использует vswhere.exe когда доступен
- Возвращается к стандартным путям установки

### Настройка окружения
- Выполняет vcvarsall.bat для настройки MSVC окружения
- Обрабатывает переменные PATH, INCLUDE, и LIB
- Поддерживает архитектуры x86 и x64

### Windows-специфичные возможности
- Правильные расширения файлов .exe, .dll, .lib
- Windows-специфичные флаги компиляции
- Объединение статических библиотек в стиле MSVC
- Поддержка линковки подсистем Windows

## Ограничения

1. **Поддержка ассемблера** - Ограниченная поддержка ассемблера (ml64/ml)
2. **Патчинг DAAL Kernel** - Windows-специфичный патчинг пока не реализован
3. **Отладочные символы** - Поддержка PDB может потребовать дополнительной настройки

## Устранение неполадок

### Общие проблемы

1. **Visual Studio не найдена**
   ```
   Error: Cannot find Visual Studio installation
   ```
   Решение: Установите Visual Studio Build Tools или полную Visual Studio

2. **Компилятор не найден**
   ```
   Error: Cannot find cl; try to correct your $PATH
   ```
   Решение: Запустите сборку из Visual Studio Developer Command Prompt

3. **Отсутствует vcvarsall.bat**
   ```
   Error: Cannot find vcvarsall.bat
   ```
   Решение: Убедитесь, что Visual Studio правильно установлена с инструментами C++

### Отладочная информация

Для отладки проблем toolchain можно:

1. Проверить определение ОС: Должно показать "win" для Windows
2. Проверить определение компилятора: Должно найти "cl" или "icx"
3. Изучить сгенерированные BUILD файлы в каталогах bazel-out

## Будущие улучшения

1. Улучшенная интеграция Intel компилятора
2. Лучшая поддержка отладки (PDB файлы)
3. Windows-специфичная оптимизация DAAL kernel
4. Поддержка разных версий Visual Studio
5. Поддержка кросс-компиляции

## Тестирование

Для тестирования Windows toolchain:

```bash
# Базовое тестирование компиляции C++
bazel build //dev/bazel/toolchains/test:hello_world_win

# Тестирование создания библиотеки
bazel build //dev/bazel/toolchains/test:test_lib_win

# Запуск теста
bazel run //dev/bazel/toolchains/test:hello_world_win
```

## Участие в разработке

При добавлении Windows-специфичных возможностей:

1. Тестируйте с компиляторами MSVC и Intel
2. Обеспечьте правильную обработку путей к файлам (прямые vs обратные слеши)
3. Используйте соответствующие расширения файлов (.exe, .bat)
4. Учитывайте Windows-специфичные переменные окружения
