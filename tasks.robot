*** Settings ***
Documentation     Template robot main suite.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive

*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Close the annoying modal
    Wait Until Keyword Succeeds    5x    0.8 sec    Try Close the annoying modal

Try Close the annoying modal
    Click Button    OK
    Wait Until Page Contains Element    id:head

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    ${OUTPUT_DIR}${/}orders.csv    overwrite=True
    ${orders}=    Read table from CSV    ${OUTPUT_DIR}${/}orders.csv    header=True
    [Return]    ${orders}

Fill the form
    [Arguments]    ${row_data}
    Wait Until Keyword Succeeds    5x    0.8 sec    Try Fill the form    ${row_data}

Try Fill the form
    [Arguments]    ${row_data}
    Select From List By Index    id:head    ${row_data}[Head]
    Select Radio Button    body    ${row_data}[Body]
    Input Text    css:input[type=number]    ${row_data}[Legs]
    Input Text    id:address    ${row_data}[Address]

*** Keywords ***
Preview the robot
    Click Button    id:preview
    Wait Until Element Is Visible    id:robot-preview-image
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}preview.png

*** Keywords ***
Submit the order
    Wait Until Keyword Succeeds    5x    0.8 sec    Try Submit the order

Try Submit the order
    Click Button    id:order
    Wait Until Page Contains Element    id:receipt

*** Keywords ***
Store the receipt as a PDF file
    [Arguments]    ${order_number}
    ${results_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${results_html}    ${OUTPUT_DIR}${/}receipts-pdf${/}${order_number}.pdf    overwrite=True
    [Return]    ${OUTPUT_DIR}${/}receipts-pdf${/}${order_number}.pdf

*** Keywords ***
Take a screenshot of the robot
    [Arguments]    ${order_number}
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}${order_number}.png
    [Return]    ${OUTPUT_DIR}${/}${order_number}.png

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}

*** Keywords ***
Go to order another robot
    Go To    https://robotsparebinindustries.com/#/robot-order

*** Keywords ***
Create a ZIP file of the receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts-pdf    receipts.zip

*** Keywords ***
Close Programs
    Close Browser

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close Programs
