# BPDUKPT

BPDUKPT is used to decrypt the magnatic strips and extract the encrypted tracks into track 1, track 2, track 3 and KSN

## How to Use

[Download](https://github.com/leomayleomay/BPDUKPT/archive/master.zip) BPDUKPT, unzip and drag everything inside directory *src* into your Xcode project and you are all set.

## Examples

```
NSString *magData = @"foobarbaz"; // this is the magnetic strips data captured from the card reader
BPDUKPTIDTechParser *parser = [[BPDUKPTIDTechParser alloc] initWithHID:magData];
BPDUKPTParsingResult *result = [parser parse];

NSLog(@"the encrypted track 1 is: %@", result.track1);
NSLog(@"the encrypted track 2 is: %@", result.track2);
NSLog(@"the encrypted track 3 is: %@", result.track3);
NSLog(@"the KSN is: %@", result.ksn);
```

## License

Use and distribution of licensed under the BSD license. See the [LICENSE](https://github.com/leomayleomay/BPDUKPT/blob/master/LICENSE) file for full text.
