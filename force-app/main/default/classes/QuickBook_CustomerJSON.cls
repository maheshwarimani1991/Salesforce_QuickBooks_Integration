/**
 * QuickBook_CustomerJSON
 * 
 * This class represents the JSON response structure for customer data from QuickBooks Online API.
 * It includes nested classes for various components of the customer data structure such as 
 * billing address, shipping address, metadata, phone numbers, email addresses, and currency references.
 * The class also provides parsing functionality to convert JSON responses into Apex objects.
 */
public class QuickBook_CustomerJSON {

	public class BillAddr {
		public String Id;
		public String Line1;
		public String City;
		public String CountrySubDivisionCode;
		public String PostalCode;
		public String Lat;
		public String Long_x;
		public String Country;
	}

	public class ParentRef {
		public String value;
	}

	public class CurrencyRef {
		public String value;
		public String name;
	}

	public QueryResponse QueryResponse;
	public String timeString;

	public class PrimaryPhone {
		public String FreeFormNumber;
	}

	public class Customer {
		public Boolean Taxable;
		public BillAddr BillAddr;
		public BillAddr ShipAddr;
		public Boolean Job;
		public Boolean BillWithParent;
		public ParentRef ParentRef;
		public Integer Level;
		public Decimal Balance;
		public Decimal BalanceWithJobs;
		public CurrencyRef CurrencyRef;
		public String PreferredDeliveryMethod;
		public Boolean IsProject;
		public String domain;
		public Boolean sparse;
		public String Id;
		public String SyncToken;
		public MetaData MetaData;
		public String FullyQualifiedName;
		public String CompanyName;
		public String GivenName;
		public String FamilyName;
		public String DisplayName;
		public String PrintOnCheckName;
		public Boolean Active;
		public PrimaryPhone PrimaryPhone;
		public PrimaryEmailAddr PrimaryEmailAddr;
		public ParentRef DefaultTaxCodeRef;
		public String TaxExemptionReasonId;
		public String ResaleNum;
	}

	public class MetaData {
		public String CreateTime;
		public String LastUpdatedTime;
	}

	public class QueryResponse {
		public List<Customer> Customer;
		public Integer startPosition;
		public Integer maxResults;
	}

	public class PrimaryEmailAddr {
		public String Address;
	}
	
	public static QuickBook_CustomerJSON parse(String json) {
		return (QuickBook_CustomerJSON) System.JSON.deserialize(json, QuickBook_CustomerJSON.class);
	}

	//Custom method to parse Customer data
	public static QuickBook_CustomerJSON.Customer parseCustomer(String json) {
		return (QuickBook_CustomerJSON.Customer) System.JSON.deserialize(json, QuickBook_CustomerJSON.Customer.class);
	}
}