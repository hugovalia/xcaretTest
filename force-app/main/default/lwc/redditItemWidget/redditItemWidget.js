import { LightningElement,wire } from 'lwc';
import syncData from '@salesforce/apex/RedditController.syncData';
import getItems from '@salesforce/apex/RedditController.getItems';
import deleteItem from '@salesforce/apex/RedditController.deleteItem';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class RedditItemWidget extends LightningElement {

    columns = [
        { label: 'Titulo', fieldName: 'title' },
        { label: 'Autor', fieldName: 'author'},
        { label: 'Thumbnail', fieldName: 'thumbnail'},
        { label: 'Descripcion', fieldName: 'description', wrapText: true},
        {
            type: 'action',
            typeAttributes: { rowActions: [
                { label: 'Delete', name: 'delete' }
            ]},
        },
    ];

    @wire(getItems) items;

    loading = false;

    handleClick(e){
        try{
            
            this.loading = true;
            e.preventDefault();
            
            syncData()
            .then(_ => {
                this.loading = false;
                this.handleRefresh();
                this.sendNotification('Items Restaurados.')
            })
            .catch( errorMessage => {
                this.loading = false;
                this.sendError('Ha ocurrudo un error cuando los items estan siendo restaurados:' + e.errorMessage)
            })
        }catch(e){
            this.sendError('Ha occurrido un error cuando se estaban restaurando los items: ' + e.message);
        }
    }

    handleRowAction(e){
        try{
            this.loading = true;
            const row = e.detail.row
            deleteItem({id:row.id})
            .then(_ => {
                this.loading = false;
                this.handleRefresh();
                this.sendNotification('Item borrado exitosamente');
            })
            .catch(errorMessage => {
                this.loading = false;
                this.sendError('Ha ocurrido un error al borrar el item:' + errorMessage)
            })
        }catch(e){
            this.sendError('Ha occurrido un error cuando se estaba borrando un registro: ' + e.message);
        }
    }

    handleRefresh(){
        refreshApex(this.items);
    }

    sendError(message){
        const evt = new ShowToastEvent({
            title: 'Error',
            message,
            variant: 'error',
        });
        this.dispatchEvent(evt);
    }

    sendNotification(message){
        const evt = new ShowToastEvent({
            title: 'Exito!',
            message,
            variant: 'success',
        });
        this.dispatchEvent(evt);
    }
}