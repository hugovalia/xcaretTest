public without sharing class RedditController {

    @AuraEnabled
    public static string syncData(){
        try {
            
            HttpRequest request = new HttpRequest();
            request.setEndpoint('https://www.reddit.com/r/subreddit/new.json?sort=new');
            request.setMethod('GET');
            
            HttpResponse response = new Http().send(request);

            String body = response.getBody();

            Map<String, Object> jsonData = (Map<String, Object>) JSON.deserializeUntyped(body);

            Map<String, Object> data = (Map<String, Object>)jsonData.get('data');

            List<Object> children = (List<Object>)data.get('children');

            List<RedditItem__c> sfItems = new List<RedditItem__c>();

            for ( Object child :  children){
                Map<String,Object> childData = (Map<String,Object>)child; 
                Map<String,Object> itemData = (Map<String,Object>)childData.get('data');
                
                RedditItem__c sfItem = new RedditItem__c();
                sfItem.Title__c = itemData.get('title').toString();
                sfItem.Author__c = itemData.get('author_fullname').toString();
                sfItem.Thumbnail__c = itemData.get('thumbnail').toString();
                sfItem.Selftext__c = itemData.get('selftext').toString();
                Decimal datetimeValue = (Decimal)itemData.get('created');
                sfItem.CreatedDate__c = DateTime.newInstance(datetimeValue.longValue());
                sfItem.ExternalId__c = itemData.get('id').toString();

                System.debug(sfItem);
                
                sfItems.add(sfItem);
            }

            System.debug('items: '+ sfItems.size());

            Database.upsert(sfItems, RedditItem__c.ExternalId__c, false);

            return 'OK';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    

    @AuraEnabled(cacheable=true)
    public static List<Map<String,String>> getItems(){
        try {
            
            List<Map<String,String>> items = new List<Map<String,String>>();

            for (RedditItem__c record :  [SELECT Id,Title__c,Author__c,Thumbnail__c,Selftext__c FROM RedditItem__c ORDER BY CreatedDate__c desc]){
                Map<String,String> item = new Map<String,String>();
                item.put('title', record.Title__c);
                item.put('author', record.Author__c);
                item.put('thumbnail', record.Thumbnail__c);
                item.put('description', record.Selftext__c);
                item.put('id', record.Id);
                items.add(item);
            }

            return items;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string deleteItem(String id){
        try {
            delete [SELECT Id FROM RedditItem__c WHERE Id = :id];
            return 'OK';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}