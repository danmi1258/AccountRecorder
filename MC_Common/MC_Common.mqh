//+------------------------------------------------------------------+
//|                                           MMT_Helper_Library.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict

enum StringType {
    Type_Alphanumeric,
    Type_Uppercase,
    Type_Lowercase,
    Type_Alpha,
    Type_Numeric,
    Type_Symbol
};

class MC_Common {
    private:
    static string StringZeroArray[1];
    static bool BoolZeroArray[1];
    static int IntZeroArray[1];
    static double DoubleZeroArray[1];
    
    public:
    //array
    template<typename T>
    static int ArrayPush(T &array[], T unit);
    
    template<typename T>
    static int ArrayReserve(T &array[], int reserveSize);
    
    static int ArrayTsearch(string &array[], string value, int count=-1, int start=0, int direction=MODE_ASCEND, bool caseSensitive=true);
    
    // string
    static string StringTrim(string inputStr);
    static bool StrToBool(string inputStr);
    static bool IsAddrAbcValid (string addrAbc);
    static int AddrAbcToInt(string addrAbc, bool zeroBased=true);
    static string AddrIntToAbc(int addrInt, bool zeroBased=true);
    static string ConcatStringFromArray(string& strArray[], string delimiter = ";");
    static StringType GetStringType(string test);
    
    //uuid
    static string GetUuid();
    
    static int GetGcd(int a, int b);
    
    static bool IsDatetimeInRange(datetime subject, int startDayOfWeek, int startHour, int endDayOfWeek, int endHour);
    
    static string GetSqlDatetime(datetime source, bool appendTimeOffset=false, string timeOffset=""/*, bool calcBrokerOffset=false*/);
    
    static bool EventSetTimerReliable(int seconds);
    static bool EventSetMillisecondTimerReliable(int milliseconds);
};

template<typename T>
int MC_Common::ArrayPush(T &array[], T unit) {
    int size;
    
    size = ArraySize(array);
    ArrayResize(array, size+1);
    array[size] = unit;
    
    return size + 1;
}

template<typename T>
int MC_Common::ArrayReserve(T &array[], int reserveSize) {
    int size;
    
    size = ArraySize(array);
    ArrayResize(array, size, reserveSize);
    
    return size + reserveSize;
}

int MC_Common::ArrayTsearch(string &array[], string value, int count=-1, int start=0, int direction=MODE_ASCEND, bool caseSensitive=true) {
    if(count < 0) { count = ArraySize(array); }
    
    for(int i = start; i < count; i++) {
        if(StringCompare(array[i], value, caseSensitive) == 0) { return i; }
    }

    return -1;
}

string MC_Common::StringTrim(string inputStr) {
    return StringTrimLeft(StringTrimRight(inputStr));
}

bool MC_Common::StrToBool(string inputStr) {
    StringToLower(inputStr);
    string testStr = StringTrim(inputStr);
    
    if(StringCompare(testStr,"true") == 0 || StringCompare(testStr,"t") == 0) { return true; }
    else if(StringCompare(testStr,"false") == 0 || StringCompare(testStr,"f") == 0) { return false; }
    else return (bool)StrToInteger(testStr);
}

bool MC_Common::IsAddrAbcValid (string addrAbc) {
    return AddrAbcToInt(addrAbc) >= 0; // todo: this overflows eventually with zzzzzzz etc, how to check?
}

int MC_Common::AddrAbcToInt(string addrAbc, bool zeroBased=true) {
    // http://stackoverflow.com/questions/9905533/convert-excel-column-alphabet-e-g-aa-to-number-e-g-25
    
    StringToLower(addrAbc);
    int addrAbcLength = StringLen(addrAbc);
    
    string letters = "abcdefghijklmnopqrstuvwxyz";
    int lettersLength = StringLen(letters);
    
    int sum = 0;
    int j = 0;
    for (int i = addrAbcLength-1; i >= 0; i--) {
        sum += MathPow(lettersLength, j) * (StringFind(letters, StringSubstr(addrAbc, i, 1))+1);
        j++;
    }
    return sum - (int)zeroBased; //make 0-based, not 1-based
}

string MC_Common::AddrIntToAbc(int addrInt, bool zeroBased=true) {
    // http://stackoverflow.com/questions/181596/how-to-convert-a-column-number-eg-127-into-an-excel-column-eg-aa

    int dividend = addrInt + (int)zeroBased; // make 0 based, not 1 based
    string columnName ="";
    int modulo;

    while (dividend > 0)
    {
        modulo = (dividend - 1) % 26;
        columnName = CharToString((uchar)(97 + modulo)) + columnName;
        dividend = (int)((dividend - modulo) / 26);
    } 

    return columnName;
}

string MC_Common::ConcatStringFromArray(string& strArray[], string delimiter = ";") {
    int strCount = ArraySize(strArray);
    
    string finalString = "";
    for(int i = 0; i < strCount; i++) {
        finalString = StringConcatenate(finalString, strArray[i], delimiter);
    }
    
    return finalString;
}

StringType MC_Common::GetStringType(string test) {
    int len = StringLen(test);
    bool uppercase = false; bool lowercase = false; bool numeric = false;
    ushort code;
    
    for(int i= 0; i < len; i++) {
        code = StringGetChar(test, i);
        if(code >= 65 && code <= 90) { uppercase = true; }
        else if(code >= 97 && code <= 122) { lowercase = true; }
        else if(code >= 48 && code <= 57) { numeric = true; }
    }

    if((uppercase||lowercase)&&numeric){ return Type_Alphanumeric; }
    else if(uppercase||lowercase) { return Type_Alpha; }
    else if(numeric) { return Type_Numeric; }
    else return Type_Symbol;
}

// http://cs.stackexchange.com/questions/1447/what-is-most-efficient-for-gcd
int MC_Common::GetGcd(int a, int b)
{
    while(b) b ^= a ^= b ^= a %= b;
    return a;
}

// https://github.com/femtotrader/rabbit4mt4/blob/master/emit/MQL4/Include/uuid.mqh
//http://en.wikipedia.org/wiki/Universally_unique_identifier
//RFC 4122
//  A Universally Unique IDentifier (UUID) URN Namespace
//  http://tools.ietf.org/html/rfc4122.html

//+------------------------------------------------------------------+
//|UUID Version 4 (random)                                           |
//|Version 4 UUIDs use a scheme relying only on random numbers.      |
//|This algorithm sets the version number (4 bits) as well as two    |
//|reserved bits. All other bits (the remaining 122 bits) are set    |
//|using a random or pseudorandom data source. Version 4 UUIDs have  |
//|the form xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx                     |
//|where x is any hexadecimal digit and y is one of 8, 9, A, or B    |
//|(e.g., f47ac10b-58cc-4372-a567-0e02b2c3d479).                                                               |
//+------------------------------------------------------------------+
string MC_Common::GetUuid()
  {
   string alphabet_x="0123456789abcdef";
   string alphabet_y="89ab";
   string id="xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"; // 36 char = (8-4-4-4-12)
   ushort character;
   for(int i=0; i<36; i++)
     {
      if(i==8 || i==13 || i==18 || i==23)
        {
         character='-';
        }
      else if(i==14)
        {
         character='4';
        }
      else if(i==19)
        {
         character = (ushort) MathRand() % 4;
         character = StringGetChar(alphabet_y, character);
        }
      else
        {
         character = (ushort) MathRand() % 16;
         character = StringGetChar(alphabet_x, character);
        }
      id=StringSetChar(id,i,character);
     }
   return (id);
  }
//+------------------------------------------------------------------+

bool MC_Common::IsDatetimeInRange(datetime subject, int startDayOfWeek, int startHour, int endDayOfWeek, int endHour) {
    int fixedEndDayOfWeek = endDayOfWeek;
    int currentDayOfWeek = TimeDayOfWeek(subject);
    int currentHour = TimeHour(subject);
    if(endDayOfWeek < startDayOfWeek) { fixedEndDayOfWeek += 7; }
    
    return currentDayOfWeek == startDayOfWeek ? currentHour >= startHour
        : currentDayOfWeek == endDayOfWeek ? currentHour < endHour
        : currentDayOfWeek > startDayOfWeek && currentDayOfWeek < fixedEndDayOfWeek
        ;
}

string MC_Common::GetSqlDatetime(datetime source, bool appendTimeOffset=false, string timeOffset=""/*, bool calcBrokerOffset=false*/) {
    // todo: microseconds?
    
    string result = TimeToStr(source, TIME_DATE|TIME_MINUTES|TIME_SECONDS);
    
    // Format: yyyy/mm/dd hh:mm:ss[-+]xx:xx (timezone)
    // replace first .'s with //
    StringReplace(result, ".", "-");
    
    double timeOffsetNum=0;
    if(appendTimeOffset) {
        /*if(calcBrokerOffset) {
            // attempt autocalc first, if fail, then fallback on supplied time offset
            // which may be empty. if it's empty, nothing is added to string -- timestamp passed
            // without offset
            
            // E.g. if difference between TimeCurrent and TimeLocal is less than one minute, then drop the seconds and do TimeCurrent-TimeGMT to calc offset
        } else */
        if(StringLen(timeOffset) <= 0) {
            timeOffsetNum = (TimeLocal()-TimeGMT())/3600;
            
            result += StringFormat("%+03.f:%02.f"
                , MathFloor(timeOffsetNum)
                , MathAbs((timeOffsetNum-MathFloor(timeOffsetNum))*60)
                );
        }
        else { result += timeOffset; }
        
    }
    
    return result;
}

bool MC_Common::EventSetTimerReliable(int seconds) {
    int delayMilliseconds = 255;
    int delayRetries = 5;
    
    for(int attempts = 0; attempts < delayRetries; attempts++) {
        if(!EventSetTimer(seconds)) {
            Sleep(delayMilliseconds);
            continue;
        } else { return true; }
    }
    
    return false;
}

bool MC_Common::EventSetMillisecondTimerReliable(int milliseconds) {
    int delayMilliseconds = 255;
    int delayRetries = 5;
    
    for(int attempts = 0; attempts < delayRetries; attempts++) {
        if(!EventSetMillisecondTimer(milliseconds)) {
            Sleep(delayMilliseconds);
            continue;
        } else { return true; }
    }
    
    return false;
}
