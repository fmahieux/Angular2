import { Component } from '@angular/core';
import { HttpService } from '../ieseg/@ieseg/services/http.service';
import {SqlSourceType} from './shared/models/sqlsourcetype';
import { Observable } from 'rxjs';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})
export class AppComponent {
  title = 'app';
  Test: Observable<SqlSourceType>;

  constructor(private http: HttpService) {
    this.Test = this.http.get<SqlSourceType>('/api/SqlSourceType');
  }

}
