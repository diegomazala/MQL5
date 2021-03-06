//+------------------------------------------------------------------+
//|                                           DG_TransactionInfo.mq5 |
//|                               Copyright 2020, DG Financial Corp. |
//|                                           https://www.google.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, DG Financial Corp."
#property link      "https://www.google.com"
#property version   "1.0"

class DG_TransactionInfo
{
    
public:
	DG_TransactionInfo(void){};
   ~DG_TransactionInfo(void){};

    static void PrintInfo( 
                        const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result);

    static string TransactionDescription(const MqlTradeTransaction &trans);

    static string RequestDescription(const MqlTradeRequest &request);

    static string TradeResultDescription(const MqlTradeResult &result);

    static string GetRetcodeID(int retcode);
};



void DG_TransactionInfo::PrintInfo(const MqlTradeTransaction& trans,
                                const MqlTradeRequest& request,
                                const MqlTradeResult& result)
{
    //--- resultado da execução do pedido de negociação
    ulong lastOrderID = trans.order;
    ENUM_ORDER_TYPE lastOrderType = trans.order_type;
    ENUM_ORDER_STATE lastOrderState = trans.order_state;
    //--- nome do símbolo segundo o qual foi realizada a transação
    string trans_symbol = trans.symbol;
    //--- tipo de transação
    ENUM_TRADE_TRANSACTION_TYPE trans_type = trans.type;
    switch (trans.type)
    {
    case TRADE_TRANSACTION_POSITION: // alteração da posição
    {
        ulong pos_ID = trans.position;
        PrintFormat("MqlTradeTransaction: Position  #%d %s modified: SL=%.5f TP=%.5f",
                    pos_ID, trans_symbol, trans.price_sl, trans.price_tp);
    }
    break;
    case TRADE_TRANSACTION_REQUEST: // envio do pedido de negociação
        PrintFormat("MqlTradeTransaction: TRADE_TRANSACTION_REQUEST");
        break;
    case TRADE_TRANSACTION_DEAL_ADD: // adição da transação
    {
        ulong lastDealID = trans.deal;
        ENUM_DEAL_TYPE lastDealType = trans.deal_type;
        double lastDealVolume = trans.volume;
        //--- identificador da transação no sistema externo - bilhete atribuído pela bolsa
        string Exchange_ticket = "";
        if (HistoryDealSelect(lastDealID))
            Exchange_ticket = HistoryDealGetString(lastDealID, DEAL_EXTERNAL_ID);
        if (Exchange_ticket != "")
            Exchange_ticket = StringFormat("(Exchange deal=%s)", Exchange_ticket);

        PrintFormat("MqlTradeTransaction: %s deal #%d %s %s %.2f lot   %s", EnumToString(trans_type),
                    lastDealID, EnumToString(lastDealType), trans_symbol, lastDealVolume, Exchange_ticket);
    }
    break;
    case TRADE_TRANSACTION_HISTORY_ADD: // adição da ordem ao histórico
    {
        //--- identificador da transação no sistema externo - bilhete atribuído pela bolsa
        string Exchange_ticket = "";
        if (lastOrderState == ORDER_STATE_FILLED)
        {
            if (HistoryOrderSelect(lastOrderID))
                Exchange_ticket = HistoryOrderGetString(lastOrderID, ORDER_EXTERNAL_ID);
            if (Exchange_ticket != "")
                Exchange_ticket = StringFormat("(Exchange ticket=%s)", Exchange_ticket);
        }
        PrintFormat("MqlTradeTransaction: %s order #%d %s %s %s   %s", EnumToString(trans_type),
                    lastOrderID, EnumToString(lastOrderType), trans_symbol, EnumToString(lastOrderState), Exchange_ticket);
    }
    break;
    default: // outras transações
    {
        //--- identificador da ordem no sistema externo - bilhete atribuído pela Bolsa de Valores de Moscou
        string Exchange_ticket = "";
        if (lastOrderState == ORDER_STATE_PLACED)
        {
            if (OrderSelect(lastOrderID))
                Exchange_ticket = OrderGetString(ORDER_EXTERNAL_ID);
            if (Exchange_ticket != "")
                Exchange_ticket = StringFormat("Exchange ticket=%s", Exchange_ticket);
        }
        PrintFormat("MqlTradeTransaction: %s order #%d %s %s   %s", EnumToString(trans_type),
                    lastOrderID, EnumToString(lastOrderType), EnumToString(lastOrderState), Exchange_ticket);
    }
    break;
    }
    //--- bilhete da ordem
    ulong orderID_result = result.order;
    string retcode_result = GetRetcodeID(result.retcode);
    if (orderID_result != 0)
        PrintFormat("MqlTradeResult: order #%d retcode=%s ", orderID_result, retcode_result);
    //---
}

//+------------------------------------------------------------------+
//| Retorna a descrição textual da transação                         |
//+------------------------------------------------------------------+
string DG_TransactionInfo::TransactionDescription(const MqlTradeTransaction &trans)
{
    //---
    string desc = EnumToString(trans.type) + "\r\n";
    desc += "Ativo: " + trans.symbol + "\r\n";
    desc += "Bilhetagem (ticket) da operação: " + (string)trans.deal + "\r\n";
    desc += "Tipo de operação: " + EnumToString(trans.deal_type) + "\r\n";
    desc += "Bilhetagem (ticket) da ordem: " + (string)trans.order + "\r\n";
    desc += "Tipo de ordem: " + EnumToString(trans.order_type) + "\r\n";
    desc += "Estado da ordem: " + EnumToString(trans.order_state) + "\r\n";
    desc += "Ordem do tipo time: " + EnumToString(trans.time_type) + "\r\n";
    desc += "Expiração da ordem: " + TimeToString(trans.time_expiration) + "\r\n";
    desc += "Preço: " + StringFormat("%G", trans.price) + "\r\n";
    desc += "Gatilho do preço: " + StringFormat("%G", trans.price_trigger) + "\r\n";
    desc += "Stop Loss: " + StringFormat("%G", trans.price_sl) + "\r\n";
    desc += "Take Profit: " + StringFormat("%G", trans.price_tp) + "\r\n";
    desc += "Volume: " + StringFormat("%G", trans.volume) + "\r\n";
    //--- retorna a string obtida
    return desc;
}

//+------------------------------------------------------------------+
//| Retorna a descrição textual da solicitação de negociação         |
//+------------------------------------------------------------------+
string DG_TransactionInfo::RequestDescription(const MqlTradeRequest &request)
{
    //---
    string desc = EnumToString(request.action) + "\r\n";
    desc += "Ativo: " + request.symbol + "\r\n";
    desc += "Número mágico: " + StringFormat("%d", request.magic) + "\r\n";
    desc += "Bilhetagem (ticket) da ordem: " + (string)request.order + "\r\n";
    desc += "Tipo de ordem: " + EnumToString(request.type) + "\r\n";
    desc += "Preenchimento da ordem: " + EnumToString(request.type_filling) + "\r\n";
    desc += "Ordem do tipo time: " + EnumToString(request.type_time) + "\r\n";
    desc += "Expiração da ordem: " + TimeToString(request.expiration) + "\r\n";
    desc += "Preço: " + StringFormat("%G", request.price) + "\r\n";
    desc += "Pontos de desvio: " + StringFormat("%G", request.deviation) + "\r\n";
    desc += "Stop Loss: " + StringFormat("%G", request.sl) + "\r\n";
    desc += "Take Profit: " + StringFormat("%G", request.tp) + "\r\n";
    desc += "Stop Limit: " + StringFormat("%G", request.stoplimit) + "\r\n";
    desc += "Volume: " + StringFormat("%G", request.volume) + "\r\n";
    desc += "Comentário: " + request.comment + "\r\n";
    //--- retorna a string obtida
    return desc;
}


//+------------------------------------------------------------------+
//| Retorna a desc. textual do resultado da manipulação da solic.    |
//+------------------------------------------------------------------+
string DG_TransactionInfo::TradeResultDescription(const MqlTradeResult &result)
{
    //---
    string desc = "Retcode " + (string)result.retcode + "\r\n";
    desc += "ID da solicitação: " + StringFormat("%d", result.request_id) + "\r\n";
    desc += "Bilhetagem (ticket) da ordem: " + (string)result.order + "\r\n";
    desc += "Bilhetagem (ticket) da operação: " + (string)result.deal + "\r\n";
    desc += "Volume: " + StringFormat("%G", result.volume) + "\r\n";
    desc += "Preço: " + StringFormat("%G", result.price) + "\r\n";
    desc += "Compra: " + StringFormat("%G", result.ask) + "\r\n";
    desc += "Venda: " + StringFormat("%G", result.bid) + "\r\n";
    desc += "Comentário: " + result.comment + "\r\n";
    //--- retorna a string obtida
    return desc;
}

//+------------------------------------------------------------------+
//| converte códigos numéricos de respostas em códigos Mnemonic de string
//+------------------------------------------------------------------+
string DG_TransactionInfo::GetRetcodeID(int retcode)
{
    switch (retcode)
    {
    case 10004:
        return ("TRADE_RETCODE_REQUOTE");
        break;
    case 10006:
        return ("TRADE_RETCODE_REJECT");
        break;
    case 10007:
        return ("TRADE_RETCODE_CANCEL");
        break;
    case 10008:
        return ("TRADE_RETCODE_PLACED");
        break;
    case 10009:
        return ("TRADE_RETCODE_DONE");
        break;
    case 10010:
        return ("TRADE_RETCODE_DONE_PARTIAL");
        break;
    case 10011:
        return ("TRADE_RETCODE_ERROR");
        break;
    case 10012:
        return ("TRADE_RETCODE_TIMEOUT");
        break;
    case 10013:
        return ("TRADE_RETCODE_INVALID");
        break;
    case 10014:
        return ("TRADE_RETCODE_INVALID_VOLUME");
        break;
    case 10015:
        return ("TRADE_RETCODE_INVALID_PRICE");
        break;
    case 10016:
        return ("TRADE_RETCODE_INVALID_STOPS");
        break;
    case 10017:
        return ("TRADE_RETCODE_TRADE_DISABLED");
        break;
    case 10018:
        return ("TRADE_RETCODE_MARKET_CLOSED");
        break;
    case 10019:
        return ("TRADE_RETCODE_NO_MONEY");
        break;
    case 10020:
        return ("TRADE_RETCODE_PRICE_CHANGED");
        break;
    case 10021:
        return ("TRADE_RETCODE_PRICE_OFF");
        break;
    case 10022:
        return ("TRADE_RETCODE_INVALID_EXPIRATION");
        break;
    case 10023:
        return ("TRADE_RETCODE_ORDER_CHANGED");
        break;
    case 10024:
        return ("TRADE_RETCODE_TOO_MANY_REQUESTS");
        break;
    case 10025:
        return ("TRADE_RETCODE_NO_CHANGES");
        break;
    case 10026:
        return ("TRADE_RETCODE_SERVER_DISABLES_AT");
        break;
    case 10027:
        return ("TRADE_RETCODE_CLIENT_DISABLES_AT");
        break;
    case 10028:
        return ("TRADE_RETCODE_LOCKED");
        break;
    case 10029:
        return ("TRADE_RETCODE_FROZEN");
        break;
    case 10030:
        return ("TRADE_RETCODE_INVALID_FILL");
        break;
    case 10031:
        return ("TRADE_RETCODE_CONNECTION");
        break;
    case 10032:
        return ("TRADE_RETCODE_ONLY_REAL");
        break;
    case 10033:
        return ("TRADE_RETCODE_LIMIT_ORDERS");
        break;
    case 10034:
        return ("TRADE_RETCODE_LIMIT_VOLUME");
        break;
    case 10035:
        return ("TRADE_RETCODE_INVALID_ORDER");
        break;
    case 10036:
        return ("TRADE_RETCODE_POSITION_CLOSED");
        break;
    default:
        return ("TRADE_RETCODE_UNKNOWN=" + IntegerToString(retcode));
        break;
    }
    //---
}