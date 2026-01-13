# Falcon Core: Version 2.x to 3.0

## Overview

This document provides a comprehensive changelog from Falcon 2.x to Falcon 3.0. This major version includes significant architectural improvements, refactoring, and new features.

---

## Breaking Changes

### Data Type System Overhaul
- **Major refactoring of data type system** [[516d44c](https://github.com/falcon-eyrie/falcon-core/commit/516d44c56ab738ceaf48c5f3854257df95b8fe9c), [a3af8fa](https://github.com/falcon-eyrie/falcon-core/commit/a3af8fa9bb28ab8cb02f4602bbdac9ffa66eb214)] - Complete redesign of how data types are handled
- **Separated data type class from data payload class** [[2e83ad8](https://github.com/falcon-eyrie/falcon-core/commit/2e83ad8dc58652d8c671dd33196802160d7a1738)] - Data types and payloads are now distinct entities
- **Removed `Initialize` methods on data classes** [[433123f](https://github.com/falcon-eyrie/falcon-core/commit/433123f525a9d969c610a0b76f1c6002f810af68)] - Initialization now done through constructors with new ringbuffer implementation
- **Changed data type serialization format** - Now uses FlatBuffers/FlexBuffers for improved performance:
  - Schema version 2 introduced [[f8befea](https://github.com/falcon-eyrie/falcon-core/commit/f8befeae10fc550f138664f7c0efd7eddd6826f5)]
  - Added type information to FlatBuffers format [[0423e29](https://github.com/falcon-eyrie/falcon-core/commit/0423e29936403e2d5c0f1a058dcd9fbb2c3b2836)]
  - Stream data format updated to use FlexBuffers [[e7c640c](https://github.com/falcon-eyrie/falcon-core/commit/e7c640c359abd0f9a049506dce3ed4914d108fd2), [7c6af80](https://github.com/falcon-eyrie/falcon-core/commit/7c6af800333c5aaca7ab4de07db0824769494832)]
  - FlatBuffer serialization implementation [[c12ce20](https://github.com/falcon-eyrie/falcon-core/commit/c12ce20a5abb73d83f96c9c50be024b6fccf5e96), [30e24d4](https://github.com/falcon-eyrie/falcon-core/commit/30e24d4a20a9a813db2dc27eb11d9125f31e1e46)]

### API Changes
- **Merged IProcessor and ProcessorEngine classes** [[f1cbe60](https://github.com/falcon-eyrie/falcon-core/commit/f1cbe60205dcb26c0c537788989cbb08becaa6d2)] - Simplified processor architecture
- **Removed StreamConnection classes** [[ccda54f](https://github.com/falcon-eyrie/falcon-core/commit/ccda54fc31eb2e1b0a07d18d3439c99a97749453)] - Ports/slots now have direct pointers to their parents
- **Changed state creation API**:
  - Removed `create state` overload with option name [[5a200b5](https://github.com/falcon-eyrie/falcon-core/commit/5a200b58e7e5eb7d42769a781dd2bdc42090ee20)]
  - State creation now requires options lookup; error if option not found [[70dce44](https://github.com/falcon-eyrie/falcon-core/commit/70dce44df9038f03664ee7b9138a90af005de1da), [9882488](https://github.com/falcon-eyrie/falcon-core/commit/9882488394478e09837a04750f746e5c90453de8)]
  - Default external permission for static states changed to write [[70dce44](https://github.com/falcon-eyrie/falcon-core/commit/70dce44df9038f03664ee7b9138a90af005de1da)]
- **Removed flexible format for state names** [[0d268c3](https://github.com/falcon-eyrie/falcon-core/commit/0d268c3a234657d9d1fb0d2318ee2ea04cd56b2b), [2665979](https://github.com/falcon-eyrie/falcon-core/commit/26659792f95fa168ba340e4ea4b5b47b0520eb7c)] - Standardized naming convention
- **Changed graph configuration format** [[cda40a3](https://github.com/falcon-eyrie/falcon-core/commit/cda40a3ffaee0a1d9bf4303b6499e98aa5c81be7), [4e52493](https://github.com/falcon-eyrie/falcon-core/commit/4e5249325bc29c27c0fc8ecc6d116cd01a2fcccc)] - New YAML structure (manages both versions with warnings [[4a1f499](https://github.com/falcon-eyrie/falcon-core/commit/4a1f499e1b6e852101c18fd5b68b0946aee1bb2b)])

### Build System
- **Moved from C++11 to C++17** [[18cf842](https://github.com/falcon-eyrie/falcon-core/commit/18cf842c7a28d8e77a7f7a10dd7080c00ea9bc6d)] - Requires modern compiler support
- **Changed CMake structure** [[47062f2](https://github.com/falcon-eyrie/falcon-core/commit/47062f2dd34202fb3f12d3083235bfb48807f5a5), [b9f8305](https://github.com/falcon-eyrie/falcon-core/commit/b9f83057d85ff0f2ee70ab96f4446fdc0230734f)] - Extensions now in separate repository
- **New extension management** [[e6bf295](https://github.com/falcon-eyrie/falcon-core/commit/e6bf29544d7b0a61d0208de96494f1e69d6ca958)] - Uses `FetchContent` for dependencies
- **Upgraded dependencies** [[041cf85](https://github.com/falcon-eyrie/falcon-core/commit/041cf8509cba20a0aa22c21432f27d4d9221a9a3)]:
  - ZMQ updated - removed deprecated warnings [[d3d64cf](https://github.com/falcon-eyrie/falcon-core/commit/d3d64cf7e75283bffeb9d5a81352ad72f8f9b46d)]
  - yaml-cpp updated to >0.6 - no longer requires Boost [[e6bf295](https://github.com/falcon-eyrie/falcon-core/commit/e6bf29544d7b0a61d0208de96494f1e69d6ca958)]
  - Added LLNL/units library dependency [[d95865b](https://github.com/falcon-eyrie/falcon-core/commit/d95865b108727cd5d90f653fdc117b7d78af9d41)]
  - Added FlatBuffers library [[ea90714](https://github.com/falcon-eyrie/falcon-core/commit/ea90714eededff687f253534b4c13917ba93d2e8), [c69b5b5](https://github.com/falcon-eyrie/falcon-core/commit/c69b5b5594009700be2b653cf22fc8bb383426cd)]

### Configuration
- **Refactored configuration system** [[ddd50c5](https://github.com/falcon-eyrie/falcon-core/commit/ddd50c5fce0d1742985214171bce2276e51739ef), [73e3c49](https://github.com/falcon-eyrie/falcon-core/commit/73e3c4984d84a24e649baf0145b1898f23a0486b), [b9cbcd3](https://github.com/falcon-eyrie/falcon-core/commit/b9cbcd3c91ec1c5597e9db781a1861686de1ccc0)] - New options-based configuration with validation
- **Changed default resource location** [[ddd50c5](https://github.com/falcon-eyrie/falcon-core/commit/ddd50c5fce0d1742985214171bce2276e51739ef)] to `./` from previous paths
- **Config port changed** [[9cf46a3](https://github.com/falcon-eyrie/falcon-core/commit/9cf46a3cd68c58cc486c3e8bcde429bd845a4225)] - Fixed to 5555 when creating socket (previously configurable but broken)

---

## New Features

### Documentation System
- **Comprehensive documentation framework** [[c929939](https://github.com/falcon-eyrie/falcon-core/commit/c929939f6138cd2115b3a912d81dfc130b3593da), [3eb218b](https://github.com/falcon-eyrie/falcon-core/commit/3eb218b6905674b40848635d56482d0f7544e6e9)]:
  - Set up Doxygen and Sphinx documentation structure
  - Added C++ reference API documentation [[a43cf3a](https://github.com/falcon-eyrie/falcon-core/commit/a43cf3a235cf44014f390b22aac7c820ec52d6a8)]
  - Added developer documentation [[a43cf3a](https://github.com/falcon-eyrie/falcon-core/commit/a43cf3a235cf44014f390b22aac7c820ec52d6a8), [7e28874](https://github.com/falcon-eyrie/falcon-core/commit/7e288746b32d815525a7dbeac0a1490587174ed2)]
  - Processor documentation in table format [[5eb3534](https://github.com/falcon-eyrie/falcon-core/commit/5eb353424eff9251e361465eca2d2c854274cb73), [e2b0748](https://github.com/falcon-eyrie/falcon-core/commit/e2b0748f73783e88c4864b222f1ee06b5fef878b)]
  - Data type descriptions [[d09931b](https://github.com/falcon-eyrie/falcon-core/commit/d09931b050212715edc66a73a5ee8343525e5b2d), [a4cbbe5](https://github.com/falcon-eyrie/falcon-core/commit/a4cbbe5f6a913d6a5b90d34e56b9b774f38a8e6c)]
  - Graph system documentation [[3ff3d9f](https://github.com/falcon-eyrie/falcon-core/commit/3ff3d9f3204a4ddeeff343c0cac8d51189dd2bbc)]
  - Multiple documentation updates [[26f2b92](https://github.com/falcon-eyrie/falcon-core/commit/26f2b928f5cf09608e8b62c7539a2f5e60429444), [c1cf97e](https://github.com/falcon-eyrie/falcon-core/commit/c1cf97efb665b6456cb87bd554fbab2bbf31c299), [1a33105](https://github.com/falcon-eyrie/falcon-core/commit/1a331059559c70dae92f3eb0c511b3f9e16849bf), [6a23406](https://github.com/falcon-eyrie/falcon-core/commit/6a234060f03c6908542337c2c604e8a562b89b69)]
- **In-code documentation registration** [[37a17bd](https://github.com/falcon-eyrie/falcon-core/commit/37a17bd9e218afc51e6fe7062b6d3da5ef20ad20), [23cae0c](https://github.com/falcon-eyrie/falcon-core/commit/23cae0cd4301b23298394cfd19d6533148e99b92)] - Processors can register documentation
- **Documentation commands** [[04d8086](https://github.com/falcon-eyrie/falcon-core/commit/04d8086cc04e543d2913ee7060f64e76b3caf7b9), [8b27bb4](https://github.com/falcon-eyrie/falcon-core/commit/8b27bb481acacf3b846f45317865afdefcc45f34)] - Users can request docs via CLI (docs/d/D commands)
- **Docker installation documentation** [[c68c82d](https://github.com/falcon-eyrie/falcon-core/commit/c68c82dff47b2778c0f734de5e3a063144c4f453)]
- **Documentation organization improvements** [[d3dd1b1](https://github.com/falcon-eyrie/falcon-core/commit/d3dd1b18a03f78618dea55e03ce426334795d8d4), [59ed4b9](https://github.com/falcon-eyrie/falcon-core/commit/59ed4b91725d44557bc89e12a00190a0836b019b), [2dbaeac](https://github.com/falcon-eyrie/falcon-core/commit/2dbaeac4aa45343cad8e586edd0985755f1deca2)]
- **Example documentation** - Ripple detection example [[82c6ef3](https://github.com/falcon-eyrie/falcon-core/commit/82c6ef3273018e029cff8c4caf7dced0f644adec)]

### CLI & Commands
- **Resources command** [[ff83fe4](https://github.com/falcon-eyrie/falcon-core/commit/ff83fe400618caa517b2b7175259e63c87faedec), [58cbcbb](https://github.com/falcon-eyrie/falcon-core/commit/58cbcbb20ecdf0ed4cb76d635ab6826a0ed77eca)] - New command to list and manage resources
- **Version information** [[5564c0f](https://github.com/falcon-eyrie/falcon-core/commit/5564c0fc76f5a6c86f5dcc5a5b613f8f7a4ca7bd)] - Added versioning info on request with git tag + build timestamp [[1694827](https://github.com/falcon-eyrie/falcon-core/commit/169482715327d03cb88a90c587da2810705c5878)]
- **Extension info in versioning** [[99bc75d](https://github.com/falcon-eyrie/falcon-core/commit/99bc75de0dcef4ddaa4a1223060001c55e752f5c)] - Track extension versions
- **Improved Falcon CLI** [[8614a95](https://github.com/falcon-eyrie/falcon-core/commit/8614a951d0e6b7c2427ae657ecefe2f1d05b07eb)] with better command handling

### State Management
- **State alias export enhancements**:
  - Export description and value if state permission is readable [[483110b](https://github.com/falcon-eyrie/falcon-core/commit/483110bdb8546bb19904cc7f7d563078bd05a24c)]
  - Use value and description from alias instead of dependent [[4a69fa2](https://github.com/falcon-eyrie/falcon-core/commit/4a69fa2954ce08bf2c64942e707e8b3cb8db4c1c)]
  - Separate readable/writable states [[d3f8fa6](https://github.com/falcon-eyrie/falcon-core/commit/d3f8fa64cf3bf3036519b6d21946d1c95686e373)]
- **Shared state convenience methods** [[70b1d35](https://github.com/falcon-eyrie/falcon-core/commit/70b1d35b7d7d73e35b1367645edfdd69af47e84e), [2360f3a](https://github.com/falcon-eyrie/falcon-core/commit/2360f3aa2bb2c385dcec3b797d1771c5a780d917)] - Added convenience shared type state creation
- **Refactored shared state system** [[5b6aa4e](https://github.com/falcon-eyrie/falcon-core/commit/5b6aa4e75095c3d58e4be0cc586295cedc21f088), [0d2ff64](https://github.com/falcon-eyrie/falcon-core/commit/0d2ff64b3c7183cdb116fa153749c6fe06b18ee3)]
- **Static member functions** [[5fc8af2](https://github.com/falcon-eyrie/falcon-core/commit/5fc8af2a5f6c1125a55291954841c7976fe6470e)] for data type and data name string retrieval

### Validation & Error Handling
- **Validated options system** [[142411c](https://github.com/falcon-eyrie/falcon-core/commit/142411c864b211bc0c32e0b23372c5c84d91f773), [4c6a717](https://github.com/falcon-eyrie/falcon-core/commit/4c6a7170d1c1496e91213217377049a79ecbc93d)]:
  - Added `ValueMap` [[ddabb0f](https://github.com/falcon-eyrie/falcon-core/commit/ddabb0fdc93d6de76b2f5864ed7a73837b8f4d60)] for validated values
  - Measurement values with units support [[0c5e6c9](https://github.com/falcon-eyrie/falcon-core/commit/0c5e6c9c69f0440b145437688065d8895ebb68a3)]
  - Custom units defined in main.cpp [[0c5e6c9](https://github.com/falcon-eyrie/falcon-core/commit/0c5e6c9c69f0440b145437688065d8895ebb68a3)]
  - File and directory validation via filesystem library [[e179961](https://github.com/falcon-eyrie/falcon-core/commit/e1799612ea5f8042e331475d4e917cac620357e6)]
  - Range class with `to_string` method [[447ae9f](https://github.com/falcon-eyrie/falcon-core/commit/447ae9f6e1562bc64c0947e78158be5aeb3d69df)]
- **Improved error messages**:
  - Better error messages in `parseConnectionRule` [[fd47b19](https://github.com/falcon-eyrie/falcon-core/commit/fd47b19cec6455978d660bc0bc2262f2c9b249f6)]
  - Show existing value name in error messages [[4498d30](https://github.com/falcon-eyrie/falcon-core/commit/4498d30d09fafe3bcb4bcb25764fb44d1f42cfb8)]
  - Raise errors for unknown options [[74f87e6](https://github.com/falcon-eyrie/falcon-core/commit/74f87e6aa84b4c6a93311b789fd0ccbfb8656c69), [6f5969b](https://github.com/falcon-eyrie/falcon-core/commit/6f5969b1e6b32fbdf0df4800ce0cab466f85614b)]
  - Catch bad documentation format [[1cafdab](https://github.com/falcon-eyrie/falcon-core/commit/1cafdabe8a6e017dea76c0d1c76652e054f2d056)]
  - Add error messages for resources [[c2a67a3](https://github.com/falcon-eyrie/falcon-core/commit/c2a67a3196b16118158977213dda039f2bfe0b31)]

### Serialization
- **Serialization Encoding enum** [[b0b4523](https://github.com/falcon-eyrie/falcon-core/commit/b0b4523aa35686b4894663475fd43d3dad80575f)] added
- **YAML conversion support** [[b0b4523](https://github.com/falcon-eyrie/falcon-core/commit/b0b4523aa35686b4894663475fd43d3dad80575f)] for serialization enums
- **Common serialization code** [[9cb24d8](https://github.com/falcon-eyrie/falcon-core/commit/9cb24d8a972e00a37a2faca86d964a5d046ee5eb)] extracted to separate file
- **FlatBuffers/FlexBuffers integration** [[30e24d4](https://github.com/falcon-eyrie/falcon-core/commit/30e24d4a20a9a813db2dc27eb11d9125f31e1e46)] for high-performance serialization

### Flexibility & Usability
- **Flexible naming syntax**:
  - Variable name flexibility for state names [[2137a65](https://github.com/falcon-eyrie/falcon-core/commit/2137a6564fe3b4561bbcabebb3378e136a16f392)]
  - Equivalent separators: space, dash, underscore [[2137a65](https://github.com/falcon-eyrie/falcon-core/commit/2137a6564fe3b4561bbcabebb3378e136a16f392)]
  - Flexible processor name syntax in configuration [[e626372](https://github.com/falcon-eyrie/falcon-core/commit/e6263724a987dbe9b8f6d5d3c6ab6e7de39cb978), [cea133d](https://github.com/falcon-eyrie/falcon-core/commit/cea133d3c36b8882522b5979ea9ac959d2985690)]
  - Flexible port name parsing [[8a410aa](https://github.com/falcon-eyrie/falcon-core/commit/8a410aa7adec7a2ca695ed1e60a0cff4abd97cfd)]
- **Multi-processor specification** [[de8f790](https://github.com/falcon-eyrie/falcon-core/commit/de8f790ee8b8a366668304e685d0c09f54b3f677), [6984fee](https://github.com/falcon-eyrie/falcon-core/commit/6984fee9cc6b131674ab12d2339d1db954a3a793)] improvements
- **Stream name** [[bd208ea](https://github.com/falcon-eyrie/falcon-core/commit/bd208ea591f2545579be517b5117970db58eaa95)] added to StreamInfo object

---

## Improvements

### Performance & Code Quality
- **Performance lints** [[fb84d44](https://github.com/falcon-eyrie/falcon-core/commit/fb84d44d7e49649ea6f2d747dcc9a5965e1258c7)] applied across codebase (#133)
- **Integrated clang-tidy** [[6e19f5c](https://github.com/falcon-eyrie/falcon-core/commit/6e19f5cae9159a97eba88114c85e1f187b3ec81f)] for static analysis (#132)
- **Code formatting**:
  - Formatted entire codebase [[1c6fb83](https://github.com/falcon-eyrie/falcon-core/commit/1c6fb83ecd9a794b984f8c8750943ba0cb4cba2f), [18644b2](https://github.com/falcon-eyrie/falcon-core/commit/18644b270e433e885d5120841f5a46fc807ab490), [cea041d](https://github.com/falcon-eyrie/falcon-core/commit/cea041dc4b0acc40035bfa54a923db8b6629d891)]
  - Added clang-format CI [[32a4030](https://github.com/falcon-eyrie/falcon-core/commit/32a4030268eb43b74aeaa36ecbc91aa2a03db0b5)]
  - cpplint code cleaning [[23554ba](https://github.com/falcon-eyrie/falcon-core/commit/23554baca489356e55429ad79a8ef4079ac5e600)]
- **Memory leak fixes**:
  - Fixed memory leak due to missing virtual destructor [[17bb8ba](https://github.com/falcon-eyrie/falcon-core/commit/17bb8ba84e295c77b1fe8fe9104a633f6d62139e)] (#60)
  - Core extension memory leak hotfix [[1538cf1](https://github.com/falcon-eyrie/falcon-core/commit/1538cf1bb4d966db83d97b12e062c7d759e27a17)]
  - Removed allocation/deallocation of FlatBuffer builder [[a6c0f9b](https://github.com/falcon-eyrie/falcon-core/commit/a6c0f9b836f5e8c9c56df86c9a7c8a2f5de468c7)]
- **Code cleanup** [[13141f3](https://github.com/falcon-eyrie/falcon-core/commit/13141f3aa2765ec3c3d28900eb2ddea141e1f026), [b230973](https://github.com/falcon-eyrie/falcon-core/commit/b2309734d454a76eb17c3ea87d6c2569d07c4801), [d646f67](https://github.com/falcon-eyrie/falcon-core/commit/d646f67e188c96f6d77f8680cc61c257e0291440)]

### Build System & CI
- **Build and clang-format CI** [[32a4030](https://github.com/falcon-eyrie/falcon-core/commit/32a4030268eb43b74aeaa36ecbc91aa2a03db0b5), [a897171](https://github.com/falcon-eyrie/falcon-core/commit/a8971716d8e02a5e25dc3d1e6a66a1ce79324d41)] (#120, #121)
- **CPP build CI** [[5075944](https://github.com/falcon-eyrie/falcon-core/commit/50759441359311dbefd90f56205fa1f678b8a62e)] added
- **Debug/Release build separation** [[7f180f4](https://github.com/falcon-eyrie/falcon-core/commit/7f180f42beeaf644f8d5992ebf593120ed41e3f9)] - Different build configurations
- **Extension development mode** [[9b2fb3f](https://github.com/falcon-eyrie/falcon-core/commit/9b2fb3f541b95c0ee3cffac358d4ad2f59472153)] added
- **Simplified extension enabling** [[e70a6a3](https://github.com/falcon-eyrie/falcon-core/commit/e70a6a32ce4ceff45702494ccc0b19234271000c), [40c8e62](https://github.com/falcon-eyrie/falcon-core/commit/40c8e6252ff9e6c412e9cadad84e037ad69e2f1b)] - Extensions specified in text file, handled by CMake
- **Extension parser** [[06c07c1](https://github.com/falcon-eyrie/falcon-core/commit/06c07c1218a29d1420867556317b543b98d2a28b)] moved to separate CMake script (#127)
- **Post-build resource handling** [[cbe2e9e](https://github.com/falcon-eyrie/falcon-core/commit/cbe2e9e7e2e691d7eaf9130783e82575ea9c27e5)] - Resources copied after build/install
- **CMake improvements** [[486503a](https://github.com/falcon-eyrie/falcon-core/commit/486503abc0f74d1f7732e4518c3adcfced8e99cd), [fb6641e](https://github.com/falcon-eyrie/falcon-core/commit/fb6641e6c6b64f5c2da56cb8994171aee18d28d3)]
- **Extension version defaults** [[e10e18e](https://github.com/falcon-eyrie/falcon-core/commit/e10e18e3cb43dcb66660b608aae56f84617ff478)] - Bump to 1.0.0 by default

### Logging
- **Upgraded to g3log library** [[ce66411](https://github.com/falcon-eyrie/falcon-core/commit/ce664110dbf71c621773d99e558db4ed59043cf0)] - Complete logging system overhaul
- **Exported logging implementation** [[29652c8](https://github.com/falcon-eyrie/falcon-core/commit/29652c801d1fe4fbda7f6728d53c53cb7c67825f)] as library
- **Color support** [[186795e](https://github.com/falcon-eyrie/falcon-core/commit/186795e87ab65abbec20cbbdca8eb0c471132e76)] in console logs
- **Changed default logging path** [[6700fc4](https://github.com/falcon-eyrie/falcon-core/commit/6700fc4945c59f417adfe1266da665f5374f2d0b)] to follow filesystem hierarchy standard
- **Removed unused event levels** [[7161c74](https://github.com/falcon-eyrie/falcon-core/commit/7161c746e0f5fbf55366e7f989b01c474588c0e3)]
- **Added log to print graph file path** [[5a13c9f](https://github.com/falcon-eyrie/falcon-core/commit/5a13c9fe7ae8be7d16b5347a7ebb81243c627186)] (#129)
- **Fixed shared library error** [[dbcde54](https://github.com/falcon-eyrie/falcon-core/commit/dbcde54740cc5237b378d8b22d5797394c12e515)]

### Architecture & Refactoring
- **Refactored slot class**:
  - Created `FlushData` method [[b7f38ee](https://github.com/falcon-eyrie/falcon-core/commit/b7f38ee1724028aa427d0d14b8ca531005cf1eec)]
  - Removed timeout as property, added as option in `retrieveData` methods [[b7f38ee](https://github.com/falcon-eyrie/falcon-core/commit/b7f38ee1724028aa427d0d14b8ca531005cf1eec)]
  - Added docstrings [[e432db8](https://github.com/falcon-eyrie/falcon-core/commit/e432db83bf22fa08525cd38cc3106ee06d49a29e), [1075b7c](https://github.com/falcon-eyrie/falcon-core/commit/1075b7c03ea779d4a8acacba620eda4e6732246e), [2edc9fe](https://github.com/falcon-eyrie/falcon-core/commit/2edc9fe475a5e89eea53acb340f2c589d21b75b1)]
- **StreamInfo class** [[c4f1f39](https://github.com/falcon-eyrie/falcon-core/commit/c4f1f39b37d6f00591ded7ca18386f6a98adbf96)] separated into own file
- **String utilities** [[c7412f4](https://github.com/falcon-eyrie/falcon-core/commit/c7412f489240e34cc5d94dac8cf5c0df81050d9c), [1cafdab](https://github.com/falcon-eyrie/falcon-core/commit/1cafdabe8a6e017dea76c0d1c76652e054f2d056)] added for common operations
- **Enhanced port/slot addressing** [[9151689](https://github.com/falcon-eyrie/falcon-core/commit/91516892591acb0ffb464bf9fab0d352143d2628)] with processor class and datatype information
- **Port compatibility verification** [[9151689](https://github.com/falcon-eyrie/falcon-core/commit/91516892591acb0ffb464bf9fab0d352143d2628)] respects data type hierarchy
- **Graph management improvements**:
  - Transform server-side graph to user-side graph on request [[430bc24](https://github.com/falcon-eyrie/falcon-core/commit/430bc24bb6c2f6b22f2e12efce027e041437aecc), [8122acf](https://github.com/falcon-eyrie/falcon-core/commit/8122acff0f237ad04084cdc65a92d16d65dd568b)]
  - Loop on saved YAML then expand processor names [[28aab03](https://github.com/falcon-eyrie/falcon-core/commit/28aab038bd16d49e39db3cd798aaa0ece015bfa3)]
  - Resource type for resource list command [[c2a67a3](https://github.com/falcon-eyrie/falcon-core/commit/c2a67a3196b16118158977213dda039f2bfe0b31)]
- **Value class improvements** [[c7412f4](https://github.com/falcon-eyrie/falcon-core/commit/c7412f489240e34cc5d94dac8cf5c0df81050d9c), [2be9ed2](https://github.com/falcon-eyrie/falcon-core/commit/2be9ed23b448b91e06cf8f90de2d19313365f789), [fd47b19](https://github.com/falcon-eyrie/falcon-core/commit/fd47b19cec6455978d660bc0bc2262f2c9b249f6)] - YAML conversion and bug fixes
- **Template value checking** [[61bf8a3](https://github.com/falcon-eyrie/falcon-core/commit/61bf8a300c33eb6ca40228ecc13eea014296dc02)]
- **Type string utilities** [[6c8bff5](https://github.com/falcon-eyrie/falcon-core/commit/6c8bff5794ca98cd2d1382a338983cb5e9f270f2)] - Added char overload
- **Moved common configuration code** [[d231185](https://github.com/falcon-eyrie/falcon-core/commit/d231185f1f7ac286f9f4a30eb975bb71c7e20863)] to utilities lib for reuse

### Configuration & Resources
- **Resource management**:
  - Combine resources from all extensions [[baa72e1](https://github.com/falcon-eyrie/falcon-core/commit/baa72e1d6c182e7f3ba6f884b29c69a377942ced)]
  - Copy resources to installation path with `make install` [[6c61a14](https://github.com/falcon-eyrie/falcon-core/commit/6c61a147eebaa072ac5ad8ca2e3325c29c1b6438)]
  - Move resources to /share folder [[66c743c](https://github.com/falcon-eyrie/falcon-core/commit/66c743c363e54b8d096d06200fe46799c428c8bc)]
  - Added YAML extensions support [[a6e047a](https://github.com/falcon-eyrie/falcon-core/commit/a6e047a8d470d56d1a15c3e226fc3a4db4bc2c8a)]
  - Fixed resource path bugs [[36838ae](https://github.com/falcon-eyrie/falcon-core/commit/36838ae16d3bcec57ca258dfed8de7c274e20017), [b889c0a](https://github.com/falcon-eyrie/falcon-core/commit/b889c0a041cacee161274c440fc32631785408bd), [8c7643e](https://github.com/falcon-eyrie/falcon-core/commit/8c7643ed9d57687cce1b75e3e676a73133b2c8ff), [cdec159](https://github.com/falcon-eyrie/falcon-core/commit/cdec1591eb8dfc18bdc05fbdd5fe6b1d59ca7980)]
- **Improved configuration loading**:
  - Filesystem support with validation [[ddd50c5](https://github.com/falcon-eyrie/falcon-core/commit/ddd50c5fce0d1742985214171bce2276e51739ef)]
  - Auto-create default config path if missing [[ddd50c5](https://github.com/falcon-eyrie/falcon-core/commit/ddd50c5fce0d1742985214171bce2276e51739ef)]
  - Both graph format versions supported (with warnings) [[4a1f499](https://github.com/falcon-eyrie/falcon-core/commit/4a1f499e1b6e852101c18fd5b68b0946aee1bb2b)]
- **Parse build command inputs** [[e23b1a3](https://github.com/falcon-eyrie/falcon-core/commit/e23b1a379f747eec9f6be41b9052eca147b35dfd)] - Accept filename or string graph description
- **Option name conversion** [[475035d](https://github.com/falcon-eyrie/falcon-core/commit/475035d2cde4bf547a6f5e65f567add27556a1d2)]
- **Pass by reference optimizations** [[5af317f](https://github.com/falcon-eyrie/falcon-core/commit/5af317f45fa65c833c4ceaa8215da7fbf4ecd4e5), [392999f](https://github.com/falcon-eyrie/falcon-core/commit/392999f3160cf9fc55813e10de6e81c0eadf4e6b)]

### Bug Fixes
- **Boolean shared state** [[59cef09](https://github.com/falcon-eyrie/falcon-core/commit/59cef0989cd621ddcd40219e3b7f73e6296fcb98)] - Fixed not loading correctly with true/false strings
- **Boolean YAML serialization** [[fc820d9](https://github.com/falcon-eyrie/falcon-core/commit/fc820d9b54571a1d2a8e2e7c074ce6e9e8f4e1f6)] - Replace 0/1 with true/false
- **Multichannelfilter crash** [[eb3a1e2](https://github.com/falcon-eyrie/falcon-core/commit/eb3a1e27bbc3fb1a7aac0d29e08f0b44abc58888)] - Fixed crashing when unprepare
- **Remote graph path** [[49ec497](https://github.com/falcon-eyrie/falcon-core/commit/49ec4973779aab979a63dc788bf7c0d166f2d0fa)] - Fixed not resolving when sent from client
- **Connection parser** [[ae41cba](https://github.com/falcon-eyrie/falcon-core/commit/ae41cbaa4021d4a5bb50bf88ecee7517e97cc165)] - Fixed for slot part
- **Parsing bugs** [[de8f790](https://github.com/falcon-eyrie/falcon-core/commit/de8f790ee8b8a366668304e685d0c09f54b3f677), [cea133d](https://github.com/falcon-eyrie/falcon-core/commit/cea133d3c36b8882522b5979ea9ac959d2985690)] - Fixed in processor name and connection rule parsing
- **ZMQ communication** [[78d0aa4](https://github.com/falcon-eyrie/falcon-core/commit/78d0aa423183cb33d34d74b7e4f44e769fa2d3e6)] - Fixed instability after upgrade
- **Stream port timeout** [[6c11afd](https://github.com/falcon-eyrie/falcon-core/commit/6c11afde8ae0ab46c832741d4d63f13d91e11ff4)] - Fixed uint instead of int
- **Trailing space/newline issues** [[2ee4681](https://github.com/falcon-eyrie/falcon-core/commit/2ee46815fe09b4fffe38d78051372536758a2c06), [0b4d22d](https://github.com/falcon-eyrie/falcon-core/commit/0b4d22d0696ababb74519752fed5c9a2801fae8a), [04c5644](https://github.com/falcon-eyrie/falcon-core/commit/04c5644c4469e43a65f901ce417664f549f1ad3e)]
- **IData parent class call** [[d13c0f9](https://github.com/falcon-eyrie/falcon-core/commit/d13c0f9d2ccc364340eb9c368d56bd50fc4932ac)]
- **Template compilation** [[3d3ca26](https://github.com/falcon-eyrie/falcon-core/commit/3d3ca26acdb650b6f2236c59d303295222260a1a)] - Added constexpr is_convertible check
- **Compilation errors** [[5dff4ae](https://github.com/falcon-eyrie/falcon-core/commit/5dff4aef059e2956c20cec42531de57dcbb7b6bd), [c989a86](https://github.com/falcon-eyrie/falcon-core/commit/c989a86c11e8b8352441472824f74da9a51426d3)] - Fixed various issues
- **CleanData typo** [[320e708](https://github.com/falcon-eyrie/falcon-core/commit/320e70817e0626d9876aeea46c667a373b6aa85c)] - Restored method removed by error
- **Regex for options** [[f8b2341](https://github.com/falcon-eyrie/falcon-core/commit/f8b23415ae6f2ef6002a15ccdba269d23f0b928f)] - Removed as it doesn't always work
- **Exception handling** [[0db00a3](https://github.com/falcon-eyrie/falcon-core/commit/0db00a3366b8a1e71347a90cf0f97e483366a49e)] - Throw exception one level upper
- **Small bug fixes** [[1a63d63](https://github.com/falcon-eyrie/falcon-core/commit/1a63d636beb43f88a795f3b59cbb760ea91d497b), [44f8b3a](https://github.com/falcon-eyrie/falcon-core/commit/44f8b3afe193706fa15e351d080c4ec894640e22)]
- **Typo fixes** [[e1193da](https://github.com/falcon-eyrie/falcon-core/commit/e1193daa33f42f07fd3edae923dbdc97d9bf0672)]
- **Extension updates** [[a773c2e](https://github.com/falcon-eyrie/falcon-core/commit/a773c2eceee0cf39bdc05308b8b80da77a256469), [2c9e058](https://github.com/falcon-eyrie/falcon-core/commit/2c9e0583fbf26f10d579449cf2e4ca9ed135cdea), [6e1d120](https://github.com/falcon-eyrie/falcon-core/commit/6e1d120d4adbcab645d39641668af3d6380c7509)] - Point to correct versions
- **Debug logging** [[7d6becb](https://github.com/falcon-eyrie/falcon-core/commit/7d6becbeaa28ed0f6d4f89478e018cdc7b3fd9c7)] - Removed log messages

---

## Dependencies & Libraries

### Added
- **FlatBuffers library** [[ea90714](https://github.com/falcon-eyrie/falcon-core/commit/ea90714eededff687f253534b4c13917ba93d2e8), [c69b5b5](https://github.com/falcon-eyrie/falcon-core/commit/c69b5b5594009700be2b653cf22fc8bb383426cd)] for serialization
- **LLNL/units library** [[d95865b](https://github.com/falcon-eyrie/falcon-core/commit/d95865b108727cd5d90f653fdc117b7d78af9d41)] for measurement values
- **Filesystem library** [[e179961](https://github.com/falcon-eyrie/falcon-core/commit/e1799612ea5f8042e331475d4e917cac620357e6)] support
- **g3log** [[ce66411](https://github.com/falcon-eyrie/falcon-core/commit/ce664110dbf71c621773d99e558db4ed59043cf0)] for logging

### Updated
- **ZMQ** [[d3d64cf](https://github.com/falcon-eyrie/falcon-core/commit/d3d64cf7e75283bffeb9d5a81352ad72f8f9b46d)] - Removed deprecated API usage
- **yaml-cpp** [[e6bf295](https://github.com/falcon-eyrie/falcon-core/commit/e6bf29544d7b0a61d0208de96494f1e69d6ca958)] to >0.6 - Removed Boost dependency
- **Core extension versions** - Updated throughout development [[1538cf1](https://github.com/falcon-eyrie/falcon-core/commit/1538cf1bb4d966db83d97b12e062c7d759e27a17), [2c9e058](https://github.com/falcon-eyrie/falcon-core/commit/2c9e0583fbf26f10d579449cf2e4ca9ed135cdea), [6e1d120](https://github.com/falcon-eyrie/falcon-core/commit/6e1d120d4adbcab645d39641668af3d6380c7509)]
- **Dependencies upgrade** [[041cf85](https://github.com/falcon-eyrie/falcon-core/commit/041cf8509cba20a0aa22c21432f27d4d9221a9a3)]

### Removed
- **Boost library dependency** [[e6bf295](https://github.com/falcon-eyrie/falcon-core/commit/e6bf29544d7b0a61d0208de96494f1e69d6ca958)] - No longer needed with yaml-cpp >0.6

---

## Project Structure Changes

- **Extensions moved to separate repository** [[47062f2](https://github.com/falcon-eyrie/falcon-core/commit/47062f2dd34202fb3f12d3083235bfb48807f5a5), [b9f8305](https://github.com/falcon-eyrie/falcon-core/commit/b9f83057d85ff0f2ee70ab96f4446fdc0230734f)]
- **Resources organized in /share folder** [[66c743c](https://github.com/falcon-eyrie/falcon-core/commit/66c743c363e54b8d096d06200fe46799c428c8bc)] following standard hierarchy
- **Logging path follows filesystem hierarchy standard** [[6700fc4](https://github.com/falcon-eyrie/falcon-core/commit/6700fc4945c59f417adfe1266da665f5374f2d0b)]
- **Install path restructured** for better organization
- **Extensions managed via FetchContent** [[e6bf295](https://github.com/falcon-eyrie/falcon-core/commit/e6bf29544d7b0a61d0208de96494f1e69d6ca958)] CMake module
- **Extension files in .gitignore** [[120b1a4](https://github.com/falcon-eyrie/falcon-core/commit/120b1a4e340846e18460134ddc2ca837b95db1f3)]
- **Keep only open-source extensions** [[4facbfd](https://github.com/falcon-eyrie/falcon-core/commit/4facbfd7e804a4984ac5034de0022ee4cdc49ba6)] in release
- **Exclude data types and processors** [[395ac7c](https://github.com/falcon-eyrie/falcon-core/commit/395ac7c4dc33eaab3c2646db8eaf6d1f7b8a260f)] from compilation (optional)

---

## Documentation Improvements

- **Created CHANGELOG.md** [[1be23e1](https://github.com/falcon-eyrie/falcon-core/commit/1be23e17932485774a9cff677f43d0df104405f4)] (#126)
- **Comprehensive manual documentation** [[9429f31](https://github.com/falcon-eyrie/falcon-core/commit/9429f3129285e5b9a78a049754faef47e555f2a1), [adadd3f](https://github.com/falcon-eyrie/falcon-core/commit/adadd3fe3c54e1590aef5781d7ce60ba921a7ad5), [cd6761e](https://github.com/falcon-eyrie/falcon-core/commit/cd6761efaea0675f477737abdd452717783a6731), [c8c3f01](https://github.com/falcon-eyrie/falcon-core/commit/c8c3f015805d0113120c99db770d68f932709409)]
- **Ripple detection example** [[82c6ef3](https://github.com/falcon-eyrie/falcon-core/commit/82c6ef3273018e029cff8c4caf7dced0f644adec)] added
- **Processor categories reorganized** [[59ed4b9](https://github.com/falcon-eyrie/falcon-core/commit/59ed4b91725d44557bc89e12a00190a0836b019b)]
- **Readable processor descriptions** [[e2b0748](https://github.com/falcon-eyrie/falcon-core/commit/e2b0748f73783e88c4864b222f1ee06b5fef878b), [b455536](https://github.com/falcon-eyrie/falcon-core/commit/b455536596a782c7e112d5e0cf7d8b821cb8ff02)]
- **Installation guide updated** [[422d31b](https://github.com/falcon-eyrie/falcon-core/commit/422d31b95b55ac4223ff497de62a4bb7ce309962), [b889c0a](https://github.com/falcon-eyrie/falcon-core/commit/b889c0a041cacee161274c440fc32631785408bd)]
- **Client building documentation** [[9c0fcf1](https://github.com/falcon-eyrie/falcon-core/commit/9c0fcf18da0d1204f5476bb77ed3e3fdc6a1b2f2)]
- **README updates** [[488aa93](https://github.com/falcon-eyrie/falcon-core/commit/488aa9323d8458e86450f5a6c62e2dfeb0d32981), [4c9c6b6](https://github.com/falcon-eyrie/falcon-core/commit/4c9c6b66178c15f7d21db6b802213bf06e449762)]
- **Documentation updates** [[17a25a3](https://github.com/falcon-eyrie/falcon-core/commit/17a25a36e9635a6e454e31c10122c5f6e058b92a), [49b8a46](https://github.com/falcon-eyrie/falcon-core/commit/49b8a4604e1a6a21c58ddf103dd74817620389cd), [2367fb9](https://github.com/falcon-eyrie/falcon-core/commit/2367fb90a90fe4b012c340c47d1c896fd7c8ce10), [bbb1b27](https://github.com/falcon-eyrie/falcon-core/commit/bbb1b277fa8ccc483e7fb8e8dd58b7150bfcf411)]
- **Doc build requirements** [[7f00c16](https://github.com/falcon-eyrie/falcon-core/commit/7f00c16b69ae41d626e8be39393866c3d0411578), [4f9588c](https://github.com/falcon-eyrie/falcon-core/commit/4f9588c05c0c54ed052f0822ba84cc94a2b38247)]
- **Documentation index updates** [[0aa9e03](https://github.com/falcon-eyrie/falcon-core/commit/0aa9e03a899d887381bdf1d8515bb1393e3a9ec4), [14a3308](https://github.com/falcon-eyrie/falcon-core/commit/14a330808b341e65c907c19fdd910edb074c67a8)]
- **Remove extension-specific documentation** [[8002e8b](https://github.com/falcon-eyrie/falcon-core/commit/8002e8b170aecc77e8b8e582f043516773501ab3)]
- **Documentation fixes** [[636fcfb](https://github.com/falcon-eyrie/falcon-core/commit/636fcfb1b177d44ca281fa67ea0dde8f0a4ba74b), [197095b](https://github.com/falcon-eyrie/falcon-core/commit/197095b5d0573fce2b3eac15470fa033ec99da3b)]
- **Method name changes** [[0c230d0](https://github.com/falcon-eyrie/falcon-core/commit/0c230d0bbca912f466c7a8576b5a831e423c8467)]
- **Remove shortcut doc** [[b235ae7](https://github.com/falcon-eyrie/falcon-core/commit/b235ae7d6512d1a89620cf5e7de08c8e00da460b)] - Add documentation at registration

---
 
## Statistics

- **Total Commits**: 250+ commits analyzed
- **Major Refactorings**: 5+ architectural changes
- **New Features**: 25+ significant additions
- **Bug Fixes**: 35+ issues resolved
- **Documentation**: Comprehensive system added with 50+ documentation commits
- **Performance**: Improved through linting and optimizations
- **Code Quality**: Enhanced via CI/CD and static analysis tools

---

## Future Considerations

- Continue performance optimizations
- Expand documentation coverage
- Additional validation features
- More flexible configuration options
- Enhanced debugging capabilities

---

## Support

For issues or questions please refer to:
- Updated documentation in `/docs`
- C++ API reference [[a43cf3a](https://github.com/falcon-eyrie/falcon-core/commit/a43cf3a235cf44014f390b22aac7c820ec52d6a8)]
- Example configurations [[82c6ef3](https://github.com/falcon-eyrie/falcon-core/commit/82c6ef3273018e029cff8c4caf7dced0f644adec)]
- Community support channels

---

## Key Merge Requests

- **Performance lints** - #133 [[fb84d44](https://github.com/falcon-eyrie/falcon-core/commit/fb84d44d7e49649ea6f2d747dcc9a5965e1258c7)]
- **Integrate clang-tidy** - #132 [[6e19f5c](https://github.com/falcon-eyrie/falcon-core/commit/6e19f5cae9159a97eba88114c85e1f187b3ec81f)]
- **Format codebase** - #131 [[1c6fb83](https://github.com/falcon-eyrie/falcon-core/commit/1c6fb83ecd9a794b984f8c8750943ba0cb4cba2f)]
- **Upgrade dependencies** - #130 [[041cf85](https://github.com/falcon-eyrie/falcon-core/commit/041cf8509cba20a0aa22c21432f27d4d9221a9a3)]
- **Create CHANGELOG.md** - #126 [[1be23e1](https://github.com/falcon-eyrie/falcon-core/commit/1be23e17932485774a9cff677f43d0df104405f4)]
- **Build and clang-format CI** - #120 [[32a4030](https://github.com/falcon-eyrie/falcon-core/commit/32a4030268eb43b74aeaa36ecbc91aa2a03db0b5)]

---

**Version**: Falcon 3.0  
**Build Date**: Generated from git tag + timestamp [[1694827](https://github.com/falcon-eyrie/falcon-core/commit/169482715327d03cb88a90c587da2810705c5878)]  
**Last Updated**: Based on commit history  
**Initial Commit**: [[8f147fd](https://github.com/falcon-eyrie/falcon-core/commit/8f147fd8f24ad3051d839fbdc3cd1268ef41992d)]
