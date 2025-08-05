public class QuickBook_Map {
  
    /**
     * Map the SF Account data to the QB customer JSON
     * @param acc The account data that is mapped
     * @return the QB json that can be used to CRUD a customer in QBO
     */
    public static String mapAccountData(Account acc){
        QuickBook_CustomerJSON.Customer customer = new QuickBook_CustomerJSON.Customer();

        //Map given account fields
        customer.CompanyName = acc.Name;
        customer.Taxable = True;       
        customer.SyncToken = acc.QuickBookSyncToken__c;
        customer.sparse = True;

        //Create Shipping address
        QuickBook_CustomerJSON.BillAddr shipAddy = new QuickBook_CustomerJSON.BillAddr();
        shipAddy.City = acc.ShippingCity;
        shipAddy.Line1 = acc.ShippingStreet;
        shipAddy.CountrySubDivisionCode = acc.ShippingState;
        shipAddy.PostalCode = acc.ShippingPostalCode;
        shipAddy.Country = acc.ShippingCountry;
        customer.ShipAddr = shipAddy;
        customer.PrintOnCheckName = acc.Name;

        //Create Primary Phone
        QuickBook_CustomerJSON.PrimaryPhone phone = new QuickBook_CustomerJSON.PrimaryPhone();
        phone.FreeFormNumber = acc.Phone;
        customer.PrimaryPhone = phone;
        customer.Job = False;
        customer.IsProject = False;
        customer.Id = acc.QuickBookId__c;
        customer.DisplayName = acc.Name;

        //Create Billing Address
        QuickBook_CustomerJSON.BillAddr billAddy = new QuickBook_CustomerJSON.BillAddr();
        billAddy.City = acc.BillingCity;
        billAddy.Line1 = acc.BillingStreet;
        billAddy.CountrySubDivisionCode = acc.BillingState;
        billAddy.PostalCode = acc.BillingPostalCode;
        billAddy.Lat = String.valueOf(acc.BillingLatitude);
        billAddy.Long_x = String.valueOf(acc.BillingLongitude);
        billAddy.Country = acc.BillingCountry;
        customer.BillAddr = billAddy;

        customer.Active = True;

        return JSON.serialize(customer, True).replace('"Long_x":', '"Long":');
    }

    /**
     * Map the SF Contact data to the QB customer JSON
     * @param acc The account data that is mapped
     * @param QBID the qbid if the record is not synced
     * @return the QB json that can be used to CRUD a customer in QBO
     */
    public static String mapContactData(Contact con, String QBID){
        QuickBook_CustomerJSON.Customer customer = new QuickBook_CustomerJSON.Customer();

        //Map given contact fields
        customer.GivenName = con.FirstName;
        customer.FamilyName = con.LastName;
        customer.CompanyName = con.account.Name;
        customer.Taxable = True;
        customer.SyncToken = con.QuickBookSyncToken__c;
        customer.sparse = True;
        customer.PrintOnCheckName = con.Account.Name;
        
        //Create Primary Phone
        QuickBook_CustomerJSON.PrimaryPhone phone = new QuickBook_CustomerJSON.PrimaryPhone ();
        phone.FreeFormNumber = con.Phone;
        customer.PrimaryPhone = phone;
        
        //Create Email address
        QuickBook_CustomerJSON.PrimaryEmailAddr email = new QuickBook_CustomerJSON.PrimaryEmailAddr();
        email.Address = con.Email;
        customer.PrimaryEmailAddr = email; 
        
        //Create ParentReference
        QuickBook_CustomerJSON.ParentRef pr = new QuickBook_CustomerJSON.ParentRef();
        pr.value = con.Account.QuickBookId__c;
        if(pr.value == null){
            pr.value = QBID;
        }
        customer.ParentRef = pr;
        customer.BillWithParent = True;
        customer.Job = True;
        customer.IsProject = False;
        customer.Id = con.QuickBookId__c;
        
        //Create Billing Address
        QuickBook_CustomerJSON.BillAddr billAddy = new QuickBook_CustomerJSON.BillAddr();
        billAddy.City = con.Account.BillingCity;
        billAddy.Line1 = con.Account.BillingStreet;
        billAddy.CountrySubDivisionCode = con.Account.BillingState;
        billAddy.PostalCode = con.Account.BillingPostalCode;
        billAddy.Country = con.Account.BillingCountry;
        billAddy.Lat = String.valueOf(con.Account.BillingLatitude);
        billAddy.Long_x = String.valueOf(con.Account.BillingLongitude);
        customer.BillAddr = billAddy;

        //Create Shipping address
        QuickBook_CustomerJSON.BillAddr shipAddy = new QuickBook_CustomerJSON.BillAddr();
        shipAddy.City = con.Account.ShippingCity;
        shipAddy.Line1 = con.Account.ShippingStreet;
        shipAddy.CountrySubDivisionCode = con.Account.ShippingState;
        shipAddy.PostalCode = con.Account.ShippingPostalCode;
        shipAddy.Country = con.Account.ShippingCountry;
        customer.ShipAddr = shipAddy;       

        customer.Active = True;

        return JSON.serialize(customer, True);
    }

    /**
     * Map an invoice from Salesforce to QBO JSON
     * @param inv The invoice that is used for the mapping
     * @return The json String that is used for the body of the request callout 
     */
    public static String mapInvoice(Invoice__c inv){
        //Initialize invoice object
        QuickBook_InvoiceJSON invoiceObj = new QuickBook_InvoiceJSON();

        //Initialize line items for invoice mapping
        QuickBook_InvoiceJSON.Line line = new QuickBook_InvoiceJSON.Line();
        QuickBook_InvoiceJSON.SalesItemLineDetail detail = new QuickBook_InvoiceJSON.SalesItemLineDetail();
        invoiceObj.Line = new List<QuickBook_InvoiceJSON.Line>();
        
        //map line item fields
        line.Amount = inv.Subtotal__c;
        line.DetailType = 'SalesItemLineDetail';
        invoiceObj.Id = inv.QuickBookId__c;
        invoiceObj.SyncToken = inv.QuickBookSyncToken__c;
        invoiceObj.DueDate = inv.DueDate__c;
        invoiceObj.AllowOnlineACHPayment = True;
        invoiceObj.AllowOnlineCreditCardPayment = True;
        String invNumber = inv.name.replace('INV-', '');
        invoiceObj.DocNumber  = invNumber;
        invoiceObj.EmailStatus = 'NotSet';
        QuickBook_InvoiceJSON.EmailAddress email = new QuickBook_InvoiceJSON.EmailAddress();
        email.Address = inv.Opportunity__r.Account.Contact__r.email;
        invoiceObj.BillEmail = email;

        QuickBook_InvoiceJSON.CustomerRef customerRef = new QuickBook_InvoiceJSON.CustomerRef();
        customerRef.value = inv.Opportunity__r.Account.QuickBookId__c;
        invoiceObj.CustomerRef = customerRef;
        
        //Map description
        QuickBook_InvoiceJSON.MemoRef memoRef = new QuickBook_InvoiceJSON.MemoRef();
        memoRef.value = inv.Description__c;
        invoiceObj.CustomerMemo = memoRef;
        QuickBook_InvoiceJSON.SalesTermRef sales = new QuickBook_InvoiceJSON.SalesTermRef();
        if(inv.Terms__c == '50% deposit / Balance Prior To Shipping'){
            sales.value = '5';
        }else if(inv.Terms__c == 'Due on receipt / Balance Due'){
            sales.value = '1';
        }else if(inv.Terms__c == 'Net 15'){
            sales.value = '2';
        }else if(inv.Terms__c == 'Net 30'){
            sales.value = '3';
        }else if(inv.Terms__c == 'Partial Payment'){
            sales.value = '6';
        }else{
            sales.value = '4';
        }
        invoiceObj.SalesTermRef = sales;
        
        //Create Billing Address
        QuickBook_InvoiceJSON.BillAddr billAddy = new QuickBook_InvoiceJSON.BillAddr();
        billAddy.City = inv.Opportunity__r.Account.BillingCity;
        billAddy.Line1 = inv.Opportunity__r.Account.BillingStreet;
        billAddy.CountrySubDivisionCode = inv.Opportunity__r.Account.BillingState;
        billAddy.PostalCode = inv.Opportunity__r.Account.BillingPostalCode;
        billAddy.Country = inv.Opportunity__r.Account.BillingCountry;
        invoiceObj.BillAddr = billAddy;

        //Create Shipping Address
        QuickBook_InvoiceJSON.BillAddr shipAddy = new QuickBook_InvoiceJSON.BillAddr();
        if(inv.Opportunity__r.Account != null){
            String phone = '';
            String cName = '';

            if(inv.Opportunity__r.Account != null){
                cName = inv.Opportunity__r.Account.Name;

            }
            if(inv.Opportunity__r.Account.Contact__c != null){
                cName = inv.Opportunity__r.Account.Contact__r.Name;
            }
            String contactLine = cName + phone;

            shipAddy.Line1 = inv.Opportunity__r.Account.Name;
            shipAddy.Line2 = contactLine ;
            shipAddy.Line3 = inv.Opportunity__r.Account.ShippingStreet;
            shipAddy.Line4 = inv.Opportunity__r.Account.ShippingCity + ', '+ 
                               inv.Opportunity__r.Account.ShippingState + '  ' +
                               inv.Opportunity__r.Account.ShippingPostalCode + '\n';
            shipAddy.Lat = String.valueOf(inv.Opportunity__r.Account.ShippingLatitude);
            shipAddy.Long_x = String.valueOf(inv.Opportunity__r.Account.ShippingLongitude);
            invoiceObj.ShipAddr = shipAddy;
        }

        //map line detail fields
        QuickBook_InvoiceJSON.ItemRef itemRef = new QuickBook_InvoiceJSON.ItemRef();
        itemRef.name = 'Sales';
        itemRef.value = '1'; 
        detail.ItemRef = itemRef;

        //map taxable status for an invoice
        detail.TaxCodeRef = new QuickBook_InvoiceJSON.ItemRef();
        detail.TaxCodeRef.value = 'TAX';
        line.SalesItemLineDetail = detail;

        invoiceObj.Line.add(line);

        return JSON.serialize(invoiceObj, True).replace('"Long_x":', '"Long":');
    }

}