import { BrowserModule } from '@angular/platform-browser';
import { NgModule } from '@angular/core';
import {HttpClientModule, HttpClientXsrfModule } from '@angular/common/http';


import { AppComponent } from './app.component';


@NgModule({
  declarations: [
    AppComponent
  ],
  imports: [
    BrowserModule,
    HttpClientModule,
    HttpClientXsrfModule.withOptions({cookieName : 'Ieseg-Xsrf-Cookie' , headerName: 'Ieseg-Xsfr-Header'})
  ],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule { }
