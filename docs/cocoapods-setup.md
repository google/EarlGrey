# EarlGrey 2.0 CocoaPods Integration

The pod for EarlGrey 2.0 is split up into `EarlGreyTest` and `EarlGreyApp` - the
setup process is fairly straightforward and typical.

`EarlGreyApp` will have to be linked to your application target in your Podfile.

`EarlGreyTest` will have to be linked to all UI Test targets that you plan on
using EarlGrey 2.0 with.

Here is an extremely simple Podfile demonstrating integrating an app called
`App` with EarlGrey 2.0.

```
target 'App' do
  pod 'EarlGreyApp'
end
target 'AppUITests' do
  pod 'EarlGreyTest'
end
```

EarlGreyExample also uses CocoaPods to install EarlGrey 2.0 in its
[Podfile](https://github.com/google/EarlGrey/blob/earlgrey2/Demo/EarlGreyExample/Podfile).

For pre-release testing, please point the Podfile to the release candidate
EarlGrey CocoaPods version:

```
target 'App' do
  pod 'EarlGreyApp', '2.0.0-rc'
end
target 'AppUITests' do
  pod 'EarlGreyTest', '2.0.0-rc'
end
```
