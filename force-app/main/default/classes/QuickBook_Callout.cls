/**
 * QuickBook_Callout
 * 
 * This class handles RESTful integration between Salesforce and QuickBooks Online.
 * It performs:
 *   - Authentication and token refresh (OAuth 2.0)
 *   - Customer operations (create, fetch)
 *   - Invoice operations (create, fetch)
 *   - Error handling for API responses
 * 
 * Configuration is loaded from Custom Metadata and Custom Settings:
 *   - `QuickBook_Metadata__mdt` (API URL, Company ID, Minor Version)
 *   - `QuickBook_Credentials__c` (Client ID, Secret, Refresh Token, Auth URL)
 */
public class QuickBook_Callout {
    private String accessToken { get; set; }   // OAuth access token used for API calls
    private String refreshToken { get; set; }  // Refresh token to generate new access tokens

    private QuickBook_Credentials__c credentials; // Stores credentials from custom setting
    private QuickBook_Metadata__mdt metadata;     // Stores metadata from custom metadata

    /**
     * Constructor
     * - Loads configuration (credentials and metadata)
     * - Immediately refreshes the access token for use
     */
    public QuickBook_Callout() {
        loadConfig();
        refresh();
    }

    /**
     * Loads QuickBooks credentials and metadata configuration from Salesforce
     */
    private void loadConfig() {
        credentials = [SELECT RefreshToken__c, ClientId__c, ClientSecret__c, AuthURL__c FROM QuickBook_Credentials__c LIMIT 1];
        metadata = [SELECT BaseURL__c, CompanyId__c, MinorVersion__c FROM QuickBook_Metadata__mdt LIMIT 1];
    }

    /**
     * Refreshes the access token using stored refresh token and OAuth 2.0
     * 
     * @throws QuickBook_Exception if access token is not returned (likely expired refresh token)
     */
    private void refresh() {
        String url = credentials.AuthURL__c;
        String header = 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(credentials.ClientId__c + ':' + credentials.ClientSecret__c));
        String body = 'grant_type=refresh_token&refresh_token=' + credentials.RefreshToken__c;

        HttpResponse res = sendRequest('POST', url, header, 'application/x-www-form-urlencoded', body);

        QuickBook_GetRefreshTokenJSON json = QuickBook_GetRefreshTokenJSON.parse(res.getBody());

        if (json.access_token == null) {
            throw new QuickBook_Exception('Refresh Token has expired.');
        }

        accessToken = json.access_token;
        refreshToken = json.refresh_token;
    }

    /**
     * Retrieves a customer from QuickBooks based on Salesforce Account's QuickBookId__c
     * 
     * @param acc Salesforce Account
     * @return QuickBook_CustomerJSON parsed response from QuickBooks
     * @throws QuickBook_Exception if QuickBookId is null
     */
    public QuickBook_CustomerJSON getCustomer(Account acc) {
        if (String.isBlank(acc.QuickBookId__c)) {
            throw new QuickBook_Exception('Account not synced with QuickBooks.');
        }

        String query = 'Select * from Customer where job = False and Id = \'' + acc.QuickBookId__c + '\'';
        String url = buildQueryUrl();

        HttpResponse res = sendRequest('POST', url, 'Bearer ' + accessToken, 'application/text', query);

        return QuickBook_CustomerJSON.parse(res.getBody());
    }

    /**
     * Creates a customer in QuickBooks based on Salesforce Account
     * 
     * @param acc Salesforce Account
     * @return QuickBook_CustomerResponseJSON containing the created customer's details
     */
    public QuickBook_CustomerResponseJSON createCustomerCall(Account acc) {
        String body = QuickBook_Map.mapAccountData(acc);
        String url = buildOperationUrl('customer');

        HttpResponse res = sendRequest('POST', url, 'Bearer ' + accessToken, 'application/json', body);

        return QuickBook_CustomerResponseJSON.parse(res.getBody());
    }

    /**
     * Retrieves an invoice from QuickBooks based on Invoice__c record
     * 
     * @param inv Salesforce Invoice__c record
     * @return QuickBook_InvoiceQueryJSON parsed invoice data
     * @throws QuickBook_Exception if QuickBookId or SyncToken is missing
     */
    public QuickBook_InvoiceQueryJSON getInvoice(Invoice__c inv) {
        if (String.isBlank(inv.QuickBookId__c) || String.isBlank(inv.QuickBookSyncToken__c)) {
            throw new QuickBook_Exception('Invoice not synced with QuickBooks.');
        }

        String query = 'Select * from invoice where id = \'' + inv.QuickBookId__c + '\'';
        String url = buildQueryUrl();

        HttpResponse res = sendRequest('POST', url, 'Bearer ' + accessToken, 'application/text', query);

        return QuickBook_InvoiceQueryJSON.parse(res.getBody());
    }

    /**
     * Creates an invoice in QuickBooks from Salesforce Invoice__c record
     * 
     * @param inv Salesforce Invoice__c record
     * @return QuickBook_InvoiceResponseJSON with created invoice data
     */
    public QuickBook_InvoiceResponseJSON createInvoiceCall(Invoice__c inv) {
        String body = QuickBook_Map.mapInvoice(inv);
        String url = buildOperationUrl('invoice');

        HttpResponse res = sendRequest('POST', url, 'Bearer ' + accessToken, 'application/json', body);

        return QuickBook_InvoiceResponseJSON.parse(res.getBody());
    }

    /**
     * Updates the refresh token in QuickBook_Credentials__c object
     * NOTE: Does NOT update custom metadata (use Metadata API or Deployment for that)
     */
    public void updateRefreshToken() {
        credentials.RefreshToken__c = refreshToken;
        credentials.LastUpdatedOn__c = Datetime.now();
        update credentials;
    }

    /**
     * Sends an HTTP request to the given endpoint and validates the response
     * 
     * @param method HTTP method (POST/GET)
     * @param url Target endpoint
     * @param authHeader Authorization header value
     * @param contentType Content-Type header
     * @param body Request body (JSON or query string)
     * @return HttpResponse if response status is 200 or 201
     * @throws QuickBook_Exception if non-200/201 status or error response
     */
    private HttpResponse sendRequest(String method, String url, String authHeader, String contentType, String body) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod(method);
        req.setBody(body);
        req.setHeader('Authorization', authHeader);
        req.setHeader('Content-Type', contentType);
        req.setHeader('Accept', 'application/json');

        Http http = new Http();
        HttpResponse res = http.send(req);

        Integer statusCode = res.getStatusCode();

        if (statusCode != 200 && statusCode != 201) {
            handleResponseError(res.getBody());
            throw new QuickBook_Exception('HTTP Error: Status Code ' + statusCode + ' - ' + res.getStatus());
        }

        return res;
    }

    /**
     * Parses and handles error response from QuickBooks API
     * 
     * @param body JSON error response body
     * @throws QuickBook_Exception with first error message found
     */
    private void handleResponseError(String body) {
        if (String.isBlank(body)) return;

        try {
            QuickBook_ErrorJSON error = QuickBook_ErrorJSON.parse(body);
            if (error != null && error.Fault != null && error.Fault.Error != null && error.Fault.Error.size() > 0) {
                throw new QuickBook_Exception(String.valueOf(error.Fault.Error[0]));
            }
        } catch (Exception e) {
            // Not a QuickBooks error JSON or parsing failed
        }
    }

    /**
     * Builds a full URL for QuickBooks query endpoint (e.g., for invoice/customer retrieval)
     * 
     * @return complete query URL string
     */
    private String buildQueryUrl() {
        return metadata.BaseURL__c + '/v3/company/' + metadata.CompanyId__c + '/query?minorversion=' + metadata.MinorVersion__c;
    }

    /**
     * Builds full URL for create/update operations on QuickBooks objects
     * 
     * @param objectType 'customer', 'invoice', etc.
     * @return complete operation URL
     */
    private String buildOperationUrl(String objectType) {
        return metadata.BaseURL__c + '/v3/company/' + metadata.CompanyId__c + '/' + objectType + '?minorversion=' + metadata.MinorVersion__c;
    }
}