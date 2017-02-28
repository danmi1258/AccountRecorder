//+------------------------------------------------------------------+
//|                                               MAR_DataWriter.mqh |
//|                                          Copyright 2017, Marco Z |
//|                                       https://github.com/mazmazz |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Marco Z"
#property link      "https://github.com/mazmazz"
#property strict
//+------------------------------------------------------------------+
#define _MariaDB

#include "../MC_Common/MC_Common.mqh"
#include "../MC_Common/MC_Error.mqh"
#include "depends/SQLite3MQL4/SQLite3Base.mqh"
#include "depends/mql4-mysql.mqh"
#include "depends/mql4-postgresql.mqh"

const int MysqlDefaultPort = 3306;

enum DataWriterFunc {
    DW_Func_None,
    DW_QueryRun,
    DW_GetCsvHandle,
    DW_QueryRetrieveRows,
    DW_QueryRetrieveOne
};

enum DataWriterType {
    DW_None,
    DW_Text,
    DW_Csv,
    DW_Sqlite,
    DW_Postgres,
    DW_Mysql
};

class DataWriter {
    private:
    CSQLite3Base *sqlite;
    int dbConnectId; // mysql, postgres
    string dbUser;
    string dbPass;
    string dbName;
    string dbHost;
    int dbPort;
    int dbSocket;
    int dbClient;
    string dbConnectString;
    string filePath; // sqlite, text
    int fileHandle; // text
    string lineComment; // text
    char csvSep;
    
    string actParamDataInput;
    
    bool isInit;

    public:
    DataWriterType dbType;
    DataWriter(DataWriterType dbTypeIn, int connectRetriesIn=5, int connectRetryDelaySecs=1, bool initCommon=false, string param="", string param2="", string param3="", string param4="", int param5=-1, int param6=-1, int param7=-1);
    ~DataWriter();
    
    void setParams(string param="", string param2="", string param3="", string param4="", int param5=-1, int param6=-1, int param7=-1);
    
    bool initConnection(bool initCommon=false, string param="", string param2="", string param3="", string param4="", int param5=-1, int param6=-1, int param7=-1);
    void closeConnection(bool deinitCommon = false);
    bool reconnect();
    bool attemptReconnect();
    
    void handleError(DataWriterFunc source, string message, string extraInfo="", string funcTrace="", string params="");

    int connectRetries;
    int connectRetryDelaySecs;
    
    bool queryRun(string dataInput);
    bool getCsvHandle(int &outFileHandle);
    
    bool queryRetrieveRows(string query, string &result[][]);
    
    template<typename T>
    bool queryRetrieveOne(string query, T &result, int rowIndex = 0/*, int colIndex = 0*/);
};

void DataWriter::DataWriter(DataWriterType dbTypeIn, int connectRetriesIn=5, int connectRetryDelaySecsIn=1, bool initCommon=false, string param="", string param2="", string param3="", string param4="", int param5=-1, int param6=-1, int param7=-1) {
    dbType = dbTypeIn;
    connectRetries = connectRetriesIn;
    connectRetryDelaySecs = connectRetryDelaySecsIn;
    isInit = false;
    
    sqlite = new CSQLite3Base();
    
    if(StringLen(param) > 0) { 
        setParams(param, param2, param3, param4, param5, param6, param7);
        initConnection(initCommon); 
    }
}

void DataWriter::setParams(string param="", string param2="", string param3="", string param4="", int param5=-1, int param6=-1, int param7=-1) {
    switch(dbType) {
        case DW_Sqlite:
            filePath = param;
            break;
            
        case DW_Mysql:
            dbHost = param; dbUser = param2; dbPass = param3; dbName = param4; 
            dbPort = param5 < 0 ? MysqlDefaultPort : param5; 
            dbSocket = param6 < 0 ? 0 : param6; 
            dbClient = param7 < 0 ? 0 : param7;
            break;
            
        case DW_Postgres:
            dbConnectString = param;
            break;
            
        case DW_Text:
            filePath = param;
            csvSep = ';';
            if(StringLen(param2) > 0) { lineComment = param2; }
            else { lineComment = "-- +--------------------------+"; } // sql
            break;
            
        case DW_Csv:
            filePath = param;
            if(StringLen(param2) == 1) { csvSep = StringGetChar(param2, 0); }
            else { csvSep = ';'; }
            break;
        
        default:
            MC_Error::ThrowError(ErrorNormal, "dbType not supported", FunctionTrace, dbType);
            break;
    }
}

void DataWriter::~DataWriter() {
    closeConnection();
    if(CheckPointer(sqlite) == POINTER_DYNAMIC) { delete(sqlite); }
}



bool DataWriter::initConnection(bool initCommon=false, string param="", string param2="", string param3="", string param4="", int param5=-1, int param6=-1, int param7=-1) {
    if(StringLen(param) > 0) {
        setParams(param, param2, param3, param4, param5, param6, param7);
    }
    
    bool bResult; int iResult;
    switch(dbType) {
        case DW_Sqlite: // param = file path
            iResult = sqlite.Connect(filePath);
            if(iResult != SQLITE_OK) {
                MC_Error::ThrowError(ErrorNormal, "SQLite failed init: " + iResult + " - " + sqlite.ErrorMsg(), FunctionTrace);
                return false;
            }
            isInit = true;
            return true;

        case DW_Mysql:
            bResult = init_MySQL(dbConnectId, dbHost, dbUser, dbPass, dbName, dbPort, dbSocket, dbClient);

            if(!bResult) { 
                MC_Error::ThrowError(ErrorNormal, "MySQL failed init", FunctionTrace); 
                return false; 
            } 
            else { isInit = true; return true; }

        case DW_Postgres:
            bResult = init_PSQL(dbConnectId, dbConnectString);

            if(!bResult) { 
                MC_Error::ThrowError(ErrorNormal, "PostgresSQL failed init", FunctionTrace); 
                return false; 
            }
            else { isInit = true; return true; }
        
        case DW_Text:
        case DW_Csv:
            fileHandle = FileOpen(filePath, FILE_SHARE_READ|FILE_SHARE_WRITE|(dbType == DW_Csv ? FILE_CSV : FILE_TXT)|FILE_UNICODE, csvSep);
            
            if(fileHandle == INVALID_HANDLE) {
                MC_Error::ThrowError(ErrorNormal, "Text file could not be opened: " + GetLastError(), FunctionTrace, param);
                return false;
            } else { isInit = true; return true; }
        
        default:
            MC_Error::ThrowError(ErrorNormal, "dbType not supported", FunctionTrace, dbType);
            return false;
    }
}

void DataWriter::closeConnection(bool deinitCommon = false) {
    switch(dbType) {
        case DW_Sqlite:
            sqlite.Disconnect();
            break;
        
        case DW_Mysql:
            deinit_MySQL(dbConnectId);
            dbConnectId = 0;
            break;

        case DW_Postgres:
            deinit_PSQL(dbConnectId);
            dbConnectId = 0;
            break;

        case DW_Text:
        case DW_Csv:
            if(fileHandle != INVALID_HANDLE) { FileClose(fileHandle); }
            break;
        
        default:
            MC_Error::ThrowError(ErrorNormal, "dbType not supported", FunctionTrace, dbType);
            break;
    }
    
    isInit = false;
}

bool DataWriter::reconnect() {
    closeConnection();

    bool bResult;
    bResult = initConnection();
    if(!bResult) { 
        MC_Error::ThrowError(ErrorNormal, "Reconnect failed", FunctionTrace); 
        return false; 
    }
    else { return true; }
}

bool DataWriter::attemptReconnect() {
    bool bResult;
    for(int i = 0; i < connectRetries; i++) {
        Sleep(connectRetryDelaySecs * 1000);
        MC_Error::PrintInfo(ErrorInfo, "Reconnecting attempt " + i + ", DB type: " + dbType, FunctionTrace);

        bResult = reconnect();
        if(bResult) { return true; }
    }

    MC_Error::ThrowError(ErrorNormal, "Could not reconnect to dbType: " + dbType + " after " + connectRetries + " attempts", FunctionTrace);

    return false;
}

void DataWriter::handleError(DataWriterFunc source, string message, string extraInfo="", string funcTrace="", string params="") {
    // todo: if the issue is connectivity, then reconnect and retry the source function
    // recall source func, using params actParamDataInput and actParamForDbType
    
    switch(dbType) {
        case DW_Sqlite:
            MC_Error::ThrowError(ErrorNormal, message + extraInfo, funcTrace, params); 
            break;

        case DW_Mysql:
            MC_Error::ThrowError(ErrorNormal, message, funcTrace, params); // MYSQL lib prints error
            break;

        case DW_Postgres:
            MC_Error::ThrowError(ErrorNormal, message, funcTrace, params); // PSQL lib prints error
            break;

        case DW_Text:
            MC_Error::ThrowError(ErrorNormal, message + extraInfo, funcTrace, params); 
            break;
        
        default:
            MC_Error::ThrowError(ErrorNormal, "dbType not supported", FunctionTrace, dbType);
            break;
    }
}

bool DataWriter::queryRun(string dataInput) {
    if(!isInit) {
        MC_Error::ThrowError(ErrorNormal, "DB is not initiated", FunctionTrace, dbType);
        return false;
    }

    actParamDataInput = dataInput;
    
    int result; bool bResult; string fileContents;
    switch(dbType) {
        case DW_Sqlite: // param = file path
            result = sqlite.Exec(dataInput, true); // extra "" fixes mt4 build 640 dll param corruption
            if (result != SQLITE_OK) { 
                handleError(DW_QueryRun, "Sqlite expression failed: " + result + " - " + sqlite.ErrorMsg(), result, FunctionTrace, dataInput); 
                return false; 
            }
            else { return true; }

        case DW_Mysql:
            bResult = MySQL_Query(dbConnectId, dataInput);
            if (!bResult) { 
                handleError(DW_QueryRun, "MySQL query failed", "", FunctionTrace, dataInput); 
                return false; 
            } // MYSQL lib prints error
            else { return true; }

        case DW_Postgres:
            bResult = PSQL_Query(dbConnectId, dataInput);
            if (!bResult) { 
                handleError(DW_QueryRun, "Postgres query failed", "", FunctionTrace, dataInput); 
                return false; 
            } // PSQL lib prints error
            else { return true; }

        case DW_Text:
            dataInput = lineComment + "\n" + dataInput + "\n";

            if(fileHandle != INVALID_HANDLE) {
                if(!FileSeek(fileHandle, 0, SEEK_END)) { // todo: do while loop, while(!FileIsEnding(fileHandle) && i < 10
                    handleError(DW_QueryRun, "Could not seek file: ", GetLastError(), FunctionTrace, filePath); 
                    return false;
                }
                
                if(!FileWriteString(fileHandle, fileContents)) { 
                    handleError(DW_QueryRun, "Could not write contents: ", GetLastError(), FunctionTrace, filePath); 
                    return false; 
                }
                else { return true; }
            } else { 
                MC_Error::ThrowError(ErrorNormal, "File handle invalid", FunctionTrace, filePath); 
                return false; 
            }
            
        case DW_Csv:
            MC_Error::PrintInfo(ErrorInfo, "Skipping CSV file for queryRun, use getCsvHandle and FileWrite", FunctionTrace);
            return false;
        
        default:
            MC_Error::ThrowError(ErrorNormal, "dbType not supported", FunctionTrace, dbType);
            return false;
    }
}

bool DataWriter::getCsvHandle(int &outFileHandle) {
    // This is needed because CSV is written by FileWrite, which takes a variable number of params
    // that is determined at code level
    
    if(!isInit) {
        MC_Error::ThrowError(ErrorNormal, "DB is not initiated", FunctionTrace, dbType);
        return false;
    }
    
    switch(dbType) {
        case DW_Csv:
            if(fileHandle != INVALID_HANDLE) {
                if(!FileSeek(fileHandle, 0, SEEK_END)) { // todo: do while loop, while(!FileIsEnding(fileHandle) && i < 10);
                    handleError(DW_QueryRun, "Could not seek file: ", GetLastError(), FunctionTrace, filePath); 
                    return false;
                }
        
                outFileHandle = fileHandle;

                return true;
            } else {
                MC_Error::ThrowError(ErrorNormal, "File handle invalid", FunctionTrace, filePath); 
                return false; 
            }    
            
        default:
            MC_Error::ThrowError(ErrorNormal, "dbType is not CSV", FunctionTrace, dbType);
            return false;
    }
}

bool DataWriter::queryRetrieveRows(string query, string &result[][]) {
    // NOTE: Multidim array size needs to be hardcoded to the expected number of cols. Else, this fails.
    
    if(!isInit) {
        MC_Error::ThrowError(ErrorNormal, "DB is not initiated", FunctionTrace, dbType);
        return false;
    }
    
    int callResult; int i = 0; int j = 0;
    
    ArrayFree(result);
    
    switch(dbType) {
        case DW_Sqlite: {
            CSQLite3Table tbl;
            callResult = sqlite.Query(tbl, query);
            if(callResult != SQLITE_DONE) {
                handleError(DW_QueryRetrieveRows, "Query error: " + sqlite.ErrorMsg(), callResult, FunctionTrace, query);
                return false; 
            }
            
            int rowCount = ArraySize(tbl.m_data);
            int colCount = 0;
            ArrayResize(result, 0, rowCount);
            for (i = 0; i < rowCount; i++) {
                CSQLite3Row *row = tbl.Row(i);
                if(!CheckPointer(row)) {
                    handleError(DW_QueryRetrieveRows, "Query error: row pointer invalid", i, FunctionTrace, query);
                    continue;
                }

                ArrayResize(result, i+1);
                colCount = ArraySize(row.m_data);
                for (j = 0; j < colCount; j++) {
                    result[i][j] = row.m_data[j].GetString();
                }
            }

            if(i > 0 && j > 0) { return true; }
            else {
                handleError(DW_QueryRetrieveRows, "Query: " + i + " rows, " + j + " columns returned", i, FunctionTrace, query);
                return false;
            }
        }
        
        case DW_Mysql:
            callResult = MySQL_FetchArray(dbConnectId, query, result);
            if(callResult < 1) { 
                handleError(DW_QueryRetrieveRows, "Query did not return any rows: ", callResult, FunctionTrace, query);
                return false; 
            }
            else { return true; }
            
        case DW_Postgres:
            callResult = PSQL_FetchArray(dbConnectId, query, result);
            if(callResult < 1) { 
                handleError(DW_QueryRetrieveRows, "Query did not return any rows: ", callResult, FunctionTrace, query);
                return false; 
            }
            else { return true; }
            
        case DW_Text:
        case DW_Csv: // todo: use a library like pandas to select CSV rows/cols
            MC_Error::ThrowError(ErrorNormal, "Text and CSV not supported for retrieval", FunctionTrace, dbType);
            return false;           
    
        default:
            MC_Error::ThrowError(ErrorNormal, "dbType not supported", FunctionTrace, dbType);
            return false;
    }
}

template<typename T>
bool DataWriter::queryRetrieveOne(string query, T &result, int rowIndex = 0/*, int colIndex = 0*/) {
    if(!isInit) {
        MC_Error::ThrowError(ErrorNormal, "DB is not initiated", FunctionTrace, dbType);
        return false;
    }
    
    int colIndex = 0; // since multidim array size is hardcoded, we can only retrieve one column
    int callResult; int cols[1]; int i = 0; int j = 0; 
    string allRows[][1];
    bool queryResult; bool returnResult = false; string dbResult;
    
    switch(dbType) {
        case DW_Sqlite: {
            CSQLite3Table tbl;
            callResult = sqlite.Query(tbl, query);
            if(callResult != SQLITE_DONE) {
                handleError(DW_QueryRetrieveRows, "Query error: " + sqlite.ErrorMsg(), callResult, FunctionTrace, query);
                return false; 
            }
            
            int rowCount = ArraySize(tbl.m_data);
            int colCount = 0;
            for (i = 0; i < rowCount; i++) {
                if(i == rowIndex) {
                    CSQLite3Row *row = tbl.Row(i);
                    if(!CheckPointer(row)) {
                        handleError(DW_QueryRetrieveRows, "Query error: row pointer invalid", i, FunctionTrace, query);
                        break;
                    }

                    colCount = ArraySize(row.m_data);
                    for (j = 0; j < colCount; j++) {
                        if(j == colIndex) { 
                            dbResult = row.m_data[j].GetString();
                            returnResult = true;
                            break;
                        }
                    }
                    break;
                }
            }
        } 
        break;
        
        case DW_Mysql:
        case DW_Postgres:
            // todo: would be nice to copy these methods from the helper libraries directly
            // so we can refer to data directly by row and col
            queryResult = queryRetrieveRows(query, allRows);
            if(!queryResult) { 
                handleError(DW_QueryRetrieveOne, "Query did not return any rows: ", "", FunctionTrace, query);
                return false; 
            }
            else {
                int dim1Size = ArrayRange(allRows, 1);
                int dim0Size = ArraySize(allRows) / dim1Size;
                
                if(dim0Size < rowIndex+1/* || dim1Size < colIndex+1*/) { 
                    // we can't determine colSize valid because we already size the col dimension to the requested index
                    handleError(DW_QueryRetrieveOne, "Query did not return enough rows: ", "", FunctionTrace, query);
                    return false;
                } else {
                    dbResult = allRows[rowIndex][colIndex];
                    returnResult = true;
                    break;
                }
            }
            
        case DW_Text:
        case DW_Csv: // todo: use a library like pandas to select CSV rows/cols
            MC_Error::ThrowError(ErrorNormal, "Text and CSV not supported for retrieval", FunctionTrace, dbType);
            return false;           
    
        default:
            MC_Error::ThrowError(ErrorNormal, "dbType not supported", FunctionTrace, dbType);
            return false;
    }
    
    if(returnResult) {
        string type = typename(T);
        if(type == "int") { result = StringToInteger(dbResult); }
        else if(type =="double") { result = StringToDouble(dbResult); }
        else if(type == "bool") { result = MC_Common::StrToBool(dbResult); }
        else { result = dbResult; }
        
        return true;
    } else { 
        handleError(DW_QueryRetrieveOne, "Query did not return data: ", "", FunctionTrace, query);
        return false; 
    }
}
