module licensepool::contentlicense {
    use std::option::{Self, Option};
    use std::string::{Self, String};

    use sui::transfer;
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::url::{Self, Url};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::object_table::{Self, ObjectTable};
    use sui::event;
    
    const NOT_THE_OWNER: u64 = 0;
    const INSUFFICIENT_FUNDS: u64 = 1;
    const MIN_LICENSE_COST: u64 = 1;

    // Content License
    struct ContentLicense has key, store {
        id: UID,
        name: String,
        owner: address,
        content_url: Url,
        royalty_agreement: String,
        sui_payment: u64,
        is_active: bool,
    }
    // Content
    struct LicensePool has key {
        id: UID,
        owner: address,
        counter: u64,
        licenses: ObjectTable<u64, ContentLicense>, 
    }

    // This event will be emitted in the create_license function
     struct LicenseCreated has copy,drop{
        id: ID,
        name: String,
        owner: address,
        royalty_agreement: String,
        license_terms: String,
     }
    
     // This event will be emitted in the update_license_terms function
    struct LicenseTermUpdated has copy, drop{
        name: String,
        owner: address,
        new_license_terms: String
    }
   
    //  created a shared object so that users can modify or alter their licenses
   fun init(ctx: &mut TxContext){
    transfer::share_object{
        LicensePool{
            id:object::new(ctx),
            owner: tx_context::sender(ctx),
            counter:0,
            licenses: object_table::new(ctx),
        }
     };
   }
 
     // This function creates new license and adds it to the table
    public entry fun create_license(
        name: vector<u8>,
        content_url: vector<u8>,
        royalty_agreement: vector<u8>,
        license_terms: vector<u8>,
        sui_payment: Coin<SUI>,
        licensepool: &mut LicensePool,
        ctx: &mut TxContext
    ){
        let value = coin::value(&sui_payment);
        assert!(value == MIN_LICENSE_COST , INSUFFICIENT_FUNDS);
        transfer::public_transfer(sui_payment, licensepool.owner);

        licensepool.counter = licensepool.counter + 1;
       //create new id, id is created because we are going to use it with both devlicense and the event
        let id = Object::new(ctx);
        //emit the event 
        event:: emit(
            LicenseCreated{
                id: object::uid_to_inner(&id),
                name: String::utf8(name),
                owner: tx_context::sender(ctx),
                royalty_agreement: string::utf8(royalty_agreement),
                license_terms: string::utf8(license_terms)
            }
        );

        //creating a new license
        let license= ContentLicense{
            id: id,
            name: string::utf8(name),
            owner: tx_context::sender(ctx),
            license_terms: string::utf8(license_terms),
            content_url: url::new_unsafe_from_bytes(content_url),
            royalty_agreement: string::utf8(royalty_agreement),
            is_active: true,
        };

        //Adding license to the table
        object_table::add(&mut licensepool.licenses, licensepool.counter, license );

    }
     // With this function the user can change his/her license terms
    public entry fun update_license_terms (licensepool: &mut LicensePool, new_license_terms: vector<u8>, id:u64, ctx: &mut TxContext){
        let user_license =object_table::borrow_mut(&mut licensepool.licenses, id);
        assert!(license.owner == tx_context::sender(ctx), NOT_THE_OWNER);
        let old_value =option::swap_or_fill(&mut user_license.license_terms, string::utf8(new_license_terms));

        event::emit( LicenseTermUpdated{
            name: user.license.name,
            owner: user.license.owner,
            new_license_terms: string::utf8(new_license_terms)
        });
        _=old_value;
    }

    // With this function user can deactivate his/her account by setting is_active field of his/her license to false
        public entry fun deactivate_license (licensepool: &mut LicensePool, id:u64, ctx: &mut TxContext){
        let license =object_table::borrow_mut(&mut licensepool.licenses, id);
        assert!(license.owner == tx_context::sender(ctx), NOT_THE_OWNER);
       license.is_active=false;
    }
    public entry fun renew_license(licensepool: &mut LicensePool, id: u64, ctx: &mut TxContext) {
        let license = object_table::borrow_mut(&mut licensepool.licenses, id);
        assert!(license.owner == sender(ctx), NOT_THE_OWNER);
        license.is_active = true; 
    }

    // This function returns the license based on the id provided
    public fun get_license_info(licensepool: &LicensePool, id: u64);{
        String,
        address,
        String,
        Url,
        Option<String>,
        bool,
    } {
        let license = object_table::borrow(&licensepool.licenses, id);
        (
            license.name,
            license.owner,
            license.royalty_agreement,
            license.content_url,
            license.license_terms,
            license.is_active,
        )
    }

}
