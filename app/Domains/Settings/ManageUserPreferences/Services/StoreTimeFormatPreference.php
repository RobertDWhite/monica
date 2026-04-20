<?php

namespace App\Domains\Settings\ManageUserPreferences\Services;

use App\Interfaces\ServiceInterface;
use App\Models\User;
use App\Services\BaseService;

class StoreTimeFormatPreference extends BaseService implements ServiceInterface
{
    private array $data;

    public function rules(): array
    {
        return [
            'account_id' => 'required|uuid|exists:accounts,id',
            'author_id' => 'required|uuid|exists:users,id',
            'time_format' => 'required|string|in:12h,24h',
        ];
    }

    public function permissions(): array
    {
        return [
            'author_must_belong_to_account',
        ];
    }

    public function execute(array $data): User
    {
        $this->data = $data;

        $this->validateRules($data);
        $this->author->time_format = $this->data['time_format'];
        $this->author->save();

        return $this->author;
    }
}
