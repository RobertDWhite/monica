<?php

namespace App\Domains\Vault\ManageVault\Api\Controllers;

use App\Domains\Contact\ManageJobInformation\Services\UpdateJobInformation;
use App\Domains\Vault\ManageCompanies\Services\CreateCompany;
use App\Models\Company;
use Illuminate\Http\Request;

/**
 * @group Contact management
 *
 * @subgroup Job information
 */
class ContactJobApiController extends ContactModuleApiController
{
    public function update(Request $request, string $vaultId, string $contactId)
    {
        $companyId = $request->input('company_id');

        if (! $companyId && $request->input('company_name')) {
            $company = (new CreateCompany)->execute([
                'account_id' => $request->user()->account_id,
                'author_id' => $request->user()->id,
                'vault_id' => $vaultId,
                'name' => $request->input('company_name'),
                'type' => Company::TYPE_COMPANY,
            ]);
            $companyId = $company->id;
        }

        (new UpdateJobInformation)->execute($this->baseData($request, $vaultId, $contactId) + [
            'company_id' => $companyId ? (int) $companyId : null,
            'job_position' => $request->input('job_position'),
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }
}
