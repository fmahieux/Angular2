import { Injectable } from '@angular/core';
import { Observable, throwError } from 'rxjs';
import { catchError, retry } from 'rxjs/operators';
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { RequestOptions, RequestOptionsArgs } from '@angular/http';

@Injectable({
  providedIn: 'root'
})
export class HttpService {

  constructor(private http: HttpClient) { }

  get<T>(url: string): Observable<T> {
    return this.http.get<T>(url).pipe(
      catchError(this.handleError)
    );
  }

  put<T>(url: string, options: string) {
    this.http.put<T>(url, <T>, options);
  }

  delete<T>(url: string) {
    this.http.delete(url);
  }

  private handleError(error: HttpErrorResponse) {
    if (error.error instanceof ErrorEvent) {
      // A client-side or network error occurred. Handle it accordingly.
      console.error('An error occurred:', error.error.message);
    } else {
      // The backend returned an unsuccessful response code.
      // The response body may contain clues as to what went wrong,
      console.error(
        `Backend returned code ${error.status}, ` +
        `body was: ${error.error}`);
    }
    // return an observable with a user-facing error message
    return throwError(
      'Something bad happened; please try again later.');
  }

  private GetOptions(url): RequestOptions {
    const options: new RequestOptions {
      url: url,

    
    }
  }

}
