@EndUserText.label: 'Notification Partner'
@Metadata.allowExtensions: true
@AccessControl.authorizationCheck: #NOT_REQUIRED

define view entity ZC_PM_ORDER_PARTNER
  as projection on ZR_PM_ORDER_PARTNER
{
@UI.hidden: true
  key MaintenanceOrder,
  key PartnerFunction,
  key PartnerCounter,

      @EndUserText.label: 'Partner'
      @Consumption.valueHelpDefinition: [{
          entity: { name: 'ZI_PM_BM_Partner', element: 'Partner' }
      }]
      Partner,

      _Order : redirected to parent ZC_PM_ORDER
}