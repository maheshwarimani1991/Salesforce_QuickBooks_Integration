/**
 * Class to deserialize QuickBooks OAuth refresh token response JSON
 * This class maps JSON fields from QuickBooks API authentication response to Apex variables
 */
public class QuickBook_GetRefreshTokenJSON {
    // Number of seconds until the refresh token expires
    public Integer x_refresh_token_expires_in;
    
    // The refresh token string used to obtain new access tokens
    public String refresh_token;
    
    // The access token string used for API requests
    public String access_token;
    
    // Number of seconds until the access token expires
    public Integer expires_in;
    
    // The type of token (usually "bearer")
    public String token_type;

    /**
     * Static method to parse JSON string into QuickBook_GetRefreshTokenJSON object
     * @param json The JSON string from QuickBooks API response
     * @return QuickBook_GetRefreshTokenJSON Parsed object with token information
     */
    public static QuickBook_GetRefreshTokenJSON parse(String json) {
        return (QuickBook_GetRefreshTokenJSON) System.JSON.deserialize(json, QuickBook_GetRefreshTokenJSON.class);
    }
}