@EndUserText.label: 'Confirm Order Parameters'
define abstract entity ZS_PM_CONFIRM_PARAM
{

  @EndUserText.label: 'End Date'
  @ObjectModel.mandatory: true
  ConfEndDate   : abap.dats;

  @EndUserText.label: 'End Time'
  @ObjectModel.mandatory: true
  ConfEndTime   : abap.tims;
  
  @EndUserText.label: 'Description'
  Description : abap.char(500);
  
}
