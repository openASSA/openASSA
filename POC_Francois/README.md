# QuantLib-based POC for openASSA
## Requirements
- [Visual Studio 2019 Community](https://visualstudio.microsoft.com/downloads/)
- [Boost for msvc 14.2 64bit](https://sourceforge.net/projects/boost/files/boost-binaries/1.74.0/boost_1_74_0-msvc-14.2-64.exe/download)
  - Install this to a directory of your choice.
## Build instructions

- Checkout the code using `git` and, if required, checkout the applicable branch
- Sync the `QuantLib` submodule:
  - `git submodule init && git submodule update`
  - Ensure that the `./src/QuantLib/` directory is populated with files
- Open `./src/boost.props` in a text editor and change the `<BOOST_DIR>` entry to point to your Boost installation directory.
- Open `./src/openASSAPOC.sln` with Visual Studio 2019.
- Configure `QuantLib` project to use Boost:
  - Choose `View > Other Windows > Property Manager` from the menu bar
  - In the `Property Manager` window that opens, right-click on the `QuantLib` project
  - Choose `Add Existing Property Sheet...`
  - Browse to and select `./src/boost.props`
- Choose `Debug` or `Release` configuration (not one of the static runtime configurations)
- Choose `x64` platform.
- `Build > Rebuild Solution` from the menu bar. This will build the entire solution. The first build requires a full rebuild of QuantLib, which can take up to 20 minutes, depending on your machine.
- Resulting `LifeProduct.exe` file is generated in `./src/x64/Debug/` or `./src/x64/Release` directory

## Comments

This POC uses the base classes from the QuantLib project.  QuantLib provides a highly abstracted object-oriented class structure that integrate using common design patterns.

For this POC use the `Instrument`, `LazyObject` and `Observable` QuantLib classes as base classes, which enables us to do lazy recalculation and automatically handle cascading recalculation when an input changes.

For example, notice that the `AssuranceProduct` class is instantiated only once:

```c++
AssuranceProduct product(policyDetailsHandle, yieldHandle, mortalityHandle, lapsesHandle);
```

To evaluate different policies, the `policyDetailsHandle` variable is relinked to different input values. The change inputs is cascaded through to `product`.

For the yield curve we implement the QuantLib `InterpolatedZeroCurve` template class and for the mortality and lapse tables we implement `InterpolatedHazardRateCurve` template class. These classes provide much more than would be possible with a simple dictionary or map approach. For example, the mortality variable now has a number of useful functions, e.g. `mortality_->hazardRate()` , `mortality_->survivalProbability()` (= <sub>n</sub>p<sub>x</sub> )or `mortality->defaultProbability()` (= q<sub>x</sub> ). These classes are currently date based, instead of integer based (e.g. for age), but this can be fixed with a bit of work.

### Pros

- C++ is very fast. 1200+ "policies" per second.

- QuantLib provides a rich feature set of base classes with an opinionated framework

- Using SWIG, one can expose your classes to other languages, e.g. C#, Python. For example, see [the guide](https://www.quantlib.org/install/windows-python.shtml) to use QuantLib in Python.

- With some work, one can write an Excel plugin wrapper around the classes to do prototyping in Excel. I wouldn't recommend this for "production" work though. It can be unstable for big workbooks. See [QuantLibXL](https://www.quantlib.org/quantlibxl/) as example.

### Cons

- C++ is slow to compile
- C++ is difficult for novice programmers (pointers, etc). You can easily shoot yourself in the foot.
- Challenging to implement parallel/distributed calculations

There is a partial C# port of QuantLib: [QLNet](https://github.com/amaggiulli/QLNet), but unfortunately hazard rate curves have not been implemented there yet. The C# syntax is, however, much friendlier and compilation times are much better than the original C++ project. One sacrifices some execution speed though.
