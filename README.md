# cmake-fuzz

```
npm i cmake-fuzz
```

```cmake
find_package(cmake-fuzz REQUIRED PATHS node_modules/cmake-fuzz)
```

## API

#### `add_fuzz_executable(<target> <sources>... [LINK <libraries>...] [DURATION <seconds>] [CORPUS <path>] [CRASHES <path>] [LABELS <labels>...] [PROPERTIES <properties>...])`

#### `add_fuzz_executables(<sources>... [PREFIX <prefix>] [LINK <libraries>...] [DURATION <seconds>] [CORPUS <path>] [CRASHES <path>] [LABELS <labels>...] [PROPERTIES <properties>...])`

`CORPUS` and `CRASHES` may contain `<TARGET>`, which is replaced by the name of each fuzz target. This gives every fuzzer its own directory, such as `CORPUS corpus/<TARGET>`. Relative paths are resolved against the current source directory. By default, `CORPUS` is `${PROJECT_SOURCE_DIR}/test/fuzz/corpus/<TARGET>` and `CRASHES` is `${PROJECT_SOURCE_DIR}/test/fuzz/crashes/<TARGET>`.

## License

Apache-2.0
